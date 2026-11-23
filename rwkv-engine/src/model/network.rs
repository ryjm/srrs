// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html
// Extracted from rslib/src/rwkv/engine.rs and rslib/src/rwkv/architecture.rs
// (Anki fork, 17c63ab7f985), small-model engine (feature rwkv-sm40).

use std::io;

use super::features::CARD_FEATURES;
use super::weights::WeightMap;

const D_MODEL: usize = 64;
const HEAD_DIM: usize = 128;
const HEADS: usize = 4;
const HEAD_SIZE: usize = D_MODEL / HEADS;
const MODULE_LAYERS: [usize; 5] = [2, 4, 1, 3, 3];
const CHANNEL_MIXER_DIMS: [usize; 5] = [64; 5];
const LAYER_STEPS: &[(usize, usize)] = &[
    (0, 0),
    (1, 0),
    (2, 0),
    (3, 0),
    (4, 0),
    (0, 1),
    (1, 1),
    (3, 1),
    (4, 1),
    (1, 2),
    (3, 2),
    (4, 2),
    (1, 3),
];
const MAX_CHANNEL_MIXER_DIM: usize = 256;
const MAX_LORA_RANK: usize = 16;
/// Inputs `note_id_is_nan`, `deck_id_is_nan` and `preset_id_is_nan`.
const MISSING_ID_FLAG_FEATURES: std::ops::Range<usize> = 13..16;

fn channel_mixer_present(module: usize, layer: usize) -> bool {
    matches!((module, layer), (0, 0) | (1, 0) | (1, 3) | (2, 0))
}

pub(super) struct SrsModel {
    features_0: Linear,
    features_norm: Norm,
    features_3: Linear,
    modules: Vec<RwkvModule>,
    prehead_norm: Norm,
    head_p_0: Linear,
    p_linear: Linear,
    /// Leak-free checkpoints were trained with the three missing-ID flags
    /// (inputs 13..15) always zero.
    pub(super) leak_free_inputs: bool,
}

pub(super) struct ReviewRetrievabilityScratch {
    feature_hidden: [f32; HEAD_DIM],
    normalized_features: [f32; HEAD_DIM],
    module: ModuleQueryScratch,
    prehead: [f32; D_MODEL],
    head: [f32; HEAD_DIM],
    logits: [f32; 4],
    probabilities: [f32; 4],
}

impl Default for ReviewRetrievabilityScratch {
    fn default() -> Self {
        Self {
            feature_hidden: [0.0; HEAD_DIM],
            normalized_features: [0.0; HEAD_DIM],
            module: ModuleQueryScratch::default(),
            prehead: [0.0; D_MODEL],
            head: [0.0; HEAD_DIM],
            logits: [0.0; 4],
            probabilities: [0.0; 4],
        }
    }
}

impl SrsModel {
    /// Refuses the tiny model (no `rwkv_modules.0.blocks.1.` tensor), whose
    /// one card layer does not match SM98.
    pub(super) fn from_weights(weights: WeightMap) -> io::Result<Self> {
        let card_second_layer = "rwkv_modules.0.blocks.1.";
        if !weights
            .tensors
            .keys()
            .any(|name| name.starts_with(card_second_layer))
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "RWKV weights do not match the model",
            ));
        }
        let modules = MODULE_LAYERS
            .iter()
            .enumerate()
            .map(|(module_id, layer_count)| RwkvModule::load(&weights, module_id, *layer_count))
            .collect::<io::Result<Vec<_>>>()?;

        Ok(Self {
            features_0: weights.linear("features2card.0", CARD_FEATURES, HEAD_DIM, true)?,
            features_norm: weights.layer_norm("features2card.2", HEAD_DIM, 1e-5)?,
            features_3: weights.linear("features2card.3", HEAD_DIM, D_MODEL, true)?,
            modules,
            prehead_norm: weights.layer_norm("prehead_norm", D_MODEL, 1e-5)?,
            head_p_0: weights.linear("head_p.0", D_MODEL, HEAD_DIM, true)?,
            p_linear: weights.linear("p_linear", HEAD_DIM, 4, true)?,
            leak_free_inputs: false,
        })
    }

    /// Zeroes the inputs this checkpoint never saw set: feature 22 for the
    /// small architecture and, for leak-free checkpoints, the missing note,
    /// deck and preset flags.
    fn zero_unused_features(&self, features: &mut [f32]) {
        features[22] = 0.0;
        if self.leak_free_inputs {
            features[MISSING_ID_FLAG_FEATURES].fill(0.0);
        }
    }

    fn feature_mlp(&self, features: &[f32]) -> Vec<f32> {
        let mut features = features.to_vec();
        self.zero_unused_features(&mut features);
        let mut x = self.features_0.apply(&features);
        silu_in_place(&mut x);
        x = self.features_norm.apply(&x);
        x = self.features_3.apply(&x);
        silu_in_place(&mut x);
        x
    }

    /// The recurrent trunk of the per-review answer pass; the heads do not
    /// feed the next state and are not computed.
    pub(super) fn review_next_state(&self, features: &[f32], state: SrsStateRef<'_>) -> SrsState {
        let x = self.feature_mlp(features);

        let states = [
            state.card,
            state.deck,
            state.note,
            state.preset,
            state.global,
        ];
        let mut x = x;
        let mut v0 = [const { Vec::new() }; 5];
        let mut next: [Vec<LayerState>; 5] = std::array::from_fn(|_| Vec::new());
        for &(module_id, layer_id) in LAYER_STEPS {
            let previous = states[module_id].and_then(|state| state.layers.get(layer_id));
            let (out, value, layer_state) =
                self.modules[module_id].layers[layer_id].run(&x, &v0[module_id], previous);
            x = out;
            v0[module_id] = value;
            next[module_id].push(layer_state);
        }
        let [card, deck, note, preset, global] = std::array::from_fn(|id| ModuleState {
            layers: std::mem::take(&mut next[id]),
        });

        SrsState {
            card,
            deck,
            note,
            preset,
            global,
        }
    }

    pub(super) fn review_retrievability_features(
        &self,
        features: &[f32],
        state: SrsStateRef<'_>,
        scratch: &mut ReviewRetrievabilityScratch,
    ) -> f32 {
        let mut features = features.to_vec();
        self.zero_unused_features(&mut features);
        self.features_0
            .apply_into(&features, &mut scratch.feature_hidden);
        silu_in_place(&mut scratch.feature_hidden);
        self.features_norm
            .apply_into(&scratch.feature_hidden, &mut scratch.normalized_features);
        let mut x = [0.0; D_MODEL];
        self.features_3
            .apply_into(&scratch.normalized_features, &mut x);
        silu_in_place(&mut x);

        let states = [
            state.card,
            state.deck,
            state.note,
            state.preset,
            state.global,
        ];
        let mut v0 = [[0.0; D_MODEL]; 5];
        for &(module_id, layer_id) in LAYER_STEPS {
            let previous = states[module_id].and_then(|state| state.layers.get(layer_id));
            self.modules[module_id].layers[layer_id].run_query_into(
                &x,
                &mut v0[module_id],
                previous,
                &mut scratch.module.next,
                &mut scratch.module.layer,
            );
            x = scratch.module.next;
        }

        self.prehead_norm.apply_into(&x, &mut scratch.prehead);
        self.head_p_0
            .apply_into(&scratch.prehead, &mut scratch.head);
        relu_in_place(&mut scratch.head);
        self.p_linear.apply_into(&scratch.head, &mut scratch.logits);
        softmax_into(&scratch.logits, &mut scratch.probabilities);
        1.0 - scratch.probabilities[0]
    }
}

#[derive(Clone, Copy)]
pub(super) struct SrsStateRef<'a> {
    pub(super) card: Option<&'a ModuleState>,
    pub(super) deck: Option<&'a ModuleState>,
    pub(super) note: Option<&'a ModuleState>,
    pub(super) preset: Option<&'a ModuleState>,
    pub(super) global: Option<&'a ModuleState>,
}

pub(super) struct SrsState {
    pub(super) card: ModuleState,
    pub(super) deck: ModuleState,
    pub(super) note: ModuleState,
    pub(super) preset: ModuleState,
    pub(super) global: ModuleState,
}

struct RwkvModule {
    layers: Vec<RwkvLayer>,
}

struct ModuleQueryScratch {
    next: [f32; D_MODEL],
    layer: LayerQueryScratch,
}

impl Default for ModuleQueryScratch {
    fn default() -> Self {
        Self {
            next: [0.0; D_MODEL],
            layer: LayerQueryScratch::default(),
        }
    }
}

impl RwkvModule {
    fn load(weights: &WeightMap, module_id: usize, layer_count: usize) -> io::Result<Self> {
        let mut layers = Vec::with_capacity(layer_count);
        for layer_id in 0..layer_count {
            layers.push(RwkvLayer::load(weights, module_id, layer_id)?);
        }
        Ok(Self { layers })
    }
}

#[derive(Clone)]
pub(super) struct ModuleState {
    layers: Vec<LayerState>,
}

struct RwkvLayer {
    time_mixer: TimeMixer,
    channel_mixer: Option<ChannelMixer>,
}

struct LayerQueryScratch {
    time_output: [f32; D_MODEL],
    time: TimeMixerQueryScratch,
    channel: ChannelMixerQueryScratch,
}

impl Default for LayerQueryScratch {
    fn default() -> Self {
        Self {
            time_output: [0.0; D_MODEL],
            time: TimeMixerQueryScratch::default(),
            channel: ChannelMixerQueryScratch::default(),
        }
    }
}

impl RwkvLayer {
    fn load(weights: &WeightMap, module_id: usize, layer_id: usize) -> io::Result<Self> {
        Ok(Self {
            time_mixer: TimeMixer::load(weights, module_id, layer_id)?,
            channel_mixer: if channel_mixer_present(module_id, layer_id) {
                Some(ChannelMixer::load(weights, module_id, layer_id)?)
            } else {
                None
            },
        })
    }

    fn run(
        &self,
        input: &[f32],
        v0: &[f32],
        state: Option<&LayerState>,
    ) -> (Vec<f32>, Vec<f32>, LayerState) {
        let (x, v0, time_state) =
            self.time_mixer
                .run(input, v0, state.and_then(|state| state.time.as_ref()));
        let (x, channel_shift) = match &self.channel_mixer {
            Some(mixer) => {
                let (x, shift) =
                    mixer.run(&x, state.and_then(|state| state.channel_shift.as_ref()));
                (x, Some(shift))
            }
            None => (x, None),
        };
        (
            x,
            v0,
            LayerState {
                time: Some(time_state),
                channel_shift,
            },
        )
    }

    fn run_query_into(
        &self,
        input: &[f32],
        v0: &mut [f32; D_MODEL],
        state: Option<&LayerState>,
        out: &mut [f32; D_MODEL],
        scratch: &mut LayerQueryScratch,
    ) {
        self.time_mixer.run_query_into(
            input,
            v0,
            state.and_then(|state| state.time.as_ref()),
            &mut scratch.time_output,
            &mut scratch.time,
        );
        let Some(mixer) = &self.channel_mixer else {
            *out = scratch.time_output;
            return;
        };
        mixer.run_query_into(
            &scratch.time_output,
            state.and_then(|state| state.channel_shift.as_deref()),
            out,
            &mut scratch.channel,
        );
    }
}

#[derive(Clone)]
struct LayerState {
    time: Option<TimeState>,
    channel_shift: Option<Vec<f32>>,
}

struct TimeMixer {
    layer_id: usize,
    layer_norm: Norm,
    rkvdag_lerp: Vec<f32>,
    bonus: Vec<f32>,
    w_r: Linear,
    w_k: Linear,
    w_v: Linear,
    w_o: Linear,
    k_scale_linear: Linear,
    v_scale_linear: Linear,
    v_lora: LoraSimple,
    a_lora: LoraSimple,
    d_lora: LoraSimple,
    lora_a_g: Linear,
    lora_b_g: Linear,
    out_group_norm: Norm,
}

struct TimeMixerQueryScratch {
    x: [f32; D_MODEL],
    mixed: [[f32; D_MODEL]; 8],
    r: [f32; D_MODEL],
    k: [f32; D_MODEL],
    v: [f32; D_MODEL],
    k_scale: [f32; HEADS],
    v_scale: [f32; HEADS],
    a: [f32; D_MODEL],
    g: [f32; D_MODEL],
    w: [f32; D_MODEL],
    k_deformed: [f32; D_MODEL],
    timestep_out: [f32; D_MODEL],
    temp: [f32; D_MODEL],
    lora_hidden: [f32; MAX_LORA_RANK],
    next_row: [f32; HEAD_SIZE],
}

impl Default for TimeMixerQueryScratch {
    fn default() -> Self {
        Self {
            x: [0.0; D_MODEL],
            mixed: [[0.0; D_MODEL]; 8],
            r: [0.0; D_MODEL],
            k: [0.0; D_MODEL],
            v: [0.0; D_MODEL],
            k_scale: [0.0; HEADS],
            v_scale: [0.0; HEADS],
            a: [0.0; D_MODEL],
            g: [0.0; D_MODEL],
            w: [0.0; D_MODEL],
            k_deformed: [0.0; D_MODEL],
            timestep_out: [0.0; D_MODEL],
            temp: [0.0; D_MODEL],
            lora_hidden: [0.0; MAX_LORA_RANK],
            next_row: [0.0; HEAD_SIZE],
        }
    }
}

impl TimeMixer {
    fn load(weights: &WeightMap, module_id: usize, layer_id: usize) -> io::Result<Self> {
        let prefix = format!("rwkv_modules.{module_id}.blocks.{layer_id}.time_mixer");
        Ok(Self {
            layer_id,
            layer_norm: weights.layer_norm(&format!("{prefix}.layer_norm"), D_MODEL, 1e-5)?,
            rkvdag_lerp: weights.values(&format!("{prefix}.rkvdag_lerp"))?,
            bonus: weights.values(&format!("{prefix}.bonus"))?,
            w_r: weights.linear(&format!("{prefix}.W_r"), D_MODEL, D_MODEL, false)?,
            w_k: weights.linear(&format!("{prefix}.W_k"), D_MODEL, D_MODEL, false)?,
            w_v: weights.linear(&format!("{prefix}.W_v"), D_MODEL, D_MODEL, false)?,
            w_o: weights.linear(&format!("{prefix}.W_o"), D_MODEL, D_MODEL, false)?,
            k_scale_linear: weights.linear(
                &format!("{prefix}.k_scale_linear"),
                D_MODEL,
                HEADS,
                true,
            )?,
            v_scale_linear: weights.linear(
                &format!("{prefix}.v_scale_linear"),
                D_MODEL,
                HEADS,
                true,
            )?,
            v_lora: if layer_id == 0 {
                LoraSimple::zero(2)
            } else {
                LoraSimple::load(weights, &format!("{prefix}.v_lora_simple"), 2)?
            },
            a_lora: LoraSimple::load(weights, &format!("{prefix}.a_lora_simple"), 4)?,
            d_lora: LoraSimple::load(weights, &format!("{prefix}.d_lora_mlp"), 4)?,
            lora_a_g: weights.linear(&format!("{prefix}.lora_A_g"), D_MODEL, 4, false)?,
            lora_b_g: weights.linear(&format!("{prefix}.lora_B_g"), 4, D_MODEL, false)?,
            out_group_norm: weights.group_norm(
                &format!("{prefix}.out_group_norm"),
                HEADS,
                D_MODEL,
                64e-5,
            )?,
        })
    }

    fn run(
        &self,
        input: &[f32],
        v0: &[f32],
        state: Option<&TimeState>,
    ) -> (Vec<f32>, Vec<f32>, TimeState) {
        let x = self.layer_norm.apply(input);
        let (x_shift, state_matrix) = match state {
            Some(state) => (state.x_shift.as_slice(), state.matrix.as_slice()),
            None => (x.as_slice(), &[0.0; HEADS * HEAD_SIZE * HEAD_SIZE][..]),
        };

        let parts = self.mix_parts(&x, x_shift, v0);

        let (out, next_matrix) = single_timestep(
            &parts.r,
            &parts.k,
            &parts.v,
            &parts.w,
            &parts.a,
            &parts.k_deformed,
            state_matrix,
        );
        let out = self.mix_output(&parts, out, input);

        (
            out,
            parts.next_v0,
            TimeState {
                x_shift: x,
                matrix: next_matrix,
            },
        )
    }

    /// `x` must already be layer-normed; `x_shift` is the previous
    /// timestep's normed input for this stream (or `x` itself when the stream
    /// has no state yet).
    fn mix_parts(&self, x: &[f32], x_shift: &[f32], v0: &[f32]) -> TimeMixParts {
        let mut mixed = [0.0; D_MODEL];
        let fill_mixed = |mix_id: usize, mixed: &mut [f32; D_MODEL]| {
            let lerp_offset = mix_id * D_MODEL;
            for channel in 0..D_MODEL {
                mixed[channel] = lerp(
                    x[channel],
                    x_shift[channel],
                    self.rkvdag_lerp[lerp_offset + channel],
                );
            }
        };

        fill_mixed(0, &mut mixed);
        let r = self.w_r.apply(&mixed);
        fill_mixed(1, &mut mixed);
        let mut k = self.w_k.apply(&mixed);
        fill_mixed(6, &mut mixed);
        let mut k_scale = self.k_scale_linear.apply(&mixed);
        sigmoid_in_place(&mut k_scale);
        fill_mixed(7, &mut mixed);
        let mut v_scale = self.v_scale_linear.apply(&mixed);
        sigmoid_in_place(&mut v_scale);

        fill_mixed(2, &mut mixed);
        let (v, next_v0) = if self.layer_id == 0 {
            let v = self.w_v.apply(&mixed);
            (v.clone(), v)
        } else {
            let mut v_lerp = self.v_lora.apply_sigmoid(&mixed);
            let w_v = self.w_v.apply(&mixed);
            for channel in 0..D_MODEL {
                v_lerp[channel] = lerp(w_v[channel], v0[channel], v_lerp[channel]);
            }
            (v_lerp, v0.to_vec())
        };

        fill_mixed(4, &mut mixed);
        let a = self.a_lora.apply_sigmoid(&mixed);
        fill_mixed(5, &mut mixed);
        let mut g = self.lora_a_g.apply(&mixed);
        sigmoid_in_place(&mut g);
        g = self.lora_b_g.apply(&g);

        fill_mixed(3, &mut mixed);
        let mut w = self.d_lora.apply_tanh(&mixed);
        for value in &mut w {
            let d = -0.5 - softplus(-*value);
            *value = (-d.exp()).exp();
        }

        normalize_heads_in_place(&mut k);
        for head in 0..HEADS {
            for index in 0..HEAD_SIZE {
                k[head * HEAD_SIZE + index] *= k_scale[head];
            }
        }

        let mut v = v;
        normalize_heads_in_place(&mut v);
        for head in 0..HEADS {
            for index in 0..HEAD_SIZE {
                v[head * HEAD_SIZE + index] *= v_scale[head];
            }
        }

        let k_deformed = k.clone();
        for channel in 0..D_MODEL {
            k[channel] *= a[channel];
        }

        TimeMixParts {
            r,
            k,
            v,
            w,
            a,
            k_deformed,
            g,
            next_v0,
        }
    }

    /// Group norm, bonus, gate, output projection, and the residual add
    /// against the un-normed layer input.
    fn mix_output(
        &self,
        parts: &TimeMixParts,
        recurrence_out: Vec<f32>,
        input: &[f32],
    ) -> Vec<f32> {
        let mut out = self.out_group_norm.apply(&recurrence_out);

        let mut bonus = [0.0; D_MODEL];
        for head in 0..HEADS {
            let base = head * HEAD_SIZE;
            let mut bonus_scale = 0.0;
            for index in 0..HEAD_SIZE {
                bonus_scale +=
                    parts.r[base + index] * self.bonus[base + index] * parts.k[base + index];
            }
            for index in 0..HEAD_SIZE {
                bonus[base + index] = bonus_scale * parts.v[base + index];
            }
        }

        for channel in 0..D_MODEL {
            out[channel] = parts.g[channel] * (out[channel] + bonus[channel]);
        }
        let mut out = self.w_o.apply(&out);
        for channel in 0..D_MODEL {
            out[channel] += input[channel];
        }
        out
    }

    fn run_query_into(
        &self,
        input: &[f32],
        v0: &mut [f32; D_MODEL],
        state: Option<&TimeState>,
        out: &mut [f32; D_MODEL],
        scratch: &mut TimeMixerQueryScratch,
    ) {
        let TimeMixerQueryScratch {
            x,
            mixed,
            r,
            k,
            v,
            k_scale,
            v_scale,
            a,
            g,
            w,
            k_deformed,
            timestep_out,
            temp,
            lora_hidden,
            next_row,
        } = scratch;

        self.layer_norm.apply_into(input, x);
        let x_shift = state.map_or(x.as_slice(), |state| state.x_shift.as_slice());
        for (mix_id, mixed_row) in mixed.iter_mut().enumerate() {
            let lerp_offset = mix_id * D_MODEL;
            for channel in 0..D_MODEL {
                mixed_row[channel] = lerp(
                    x[channel],
                    x_shift[channel],
                    self.rkvdag_lerp[lerp_offset + channel],
                );
            }
        }

        self.w_r.apply_into(&mixed[0], r);
        self.w_k.apply_into(&mixed[1], k);
        self.k_scale_linear.apply_into(&mixed[6], k_scale);
        sigmoid_in_place(k_scale);
        self.v_scale_linear.apply_into(&mixed[7], v_scale);
        sigmoid_in_place(v_scale);

        if self.layer_id == 0 {
            self.w_v.apply_into(&mixed[2], v);
            v0.copy_from_slice(v);
        } else {
            self.v_lora.apply_sigmoid_into(&mixed[2], lora_hidden, v);
            self.w_v.apply_into(&mixed[2], temp);
            for channel in 0..D_MODEL {
                v[channel] = lerp(temp[channel], v0[channel], v[channel]);
            }
        }

        self.a_lora.apply_sigmoid_into(&mixed[4], lora_hidden, a);
        let gate_hidden = &mut lora_hidden[..self.lora_a_g.output];
        self.lora_a_g.apply_into(&mixed[5], gate_hidden);
        sigmoid_in_place(gate_hidden);
        self.lora_b_g.apply_into(gate_hidden, g);

        self.d_lora.apply_tanh_into(&mixed[3], lora_hidden, w);
        for value in w.iter_mut() {
            let decay = -0.5 - softplus(-*value);
            *value = (-decay.exp()).exp();
        }

        normalize_heads_in_place(k);
        for head in 0..HEADS {
            for index in 0..HEAD_SIZE {
                k[head * HEAD_SIZE + index] *= k_scale[head];
            }
        }

        normalize_heads_in_place(v);
        for head in 0..HEADS {
            for index in 0..HEAD_SIZE {
                v[head * HEAD_SIZE + index] *= v_scale[head];
            }
        }

        k_deformed.copy_from_slice(k);
        for channel in 0..D_MODEL {
            k[channel] *= a[channel];
        }

        single_timestep_query_into(
            r,
            k,
            v,
            w,
            a,
            k_deformed,
            state.map(|state| state.matrix.as_slice()),
            timestep_out,
            next_row,
        );
        self.out_group_norm.apply_into(timestep_out, temp);

        for head in 0..HEADS {
            let base = head * HEAD_SIZE;
            let mut bonus_scale = 0.0;
            for index in 0..HEAD_SIZE {
                bonus_scale += r[base + index] * self.bonus[base + index] * k[base + index];
            }
            for index in 0..HEAD_SIZE {
                let channel = base + index;
                temp[channel] = g[channel] * (temp[channel] + bonus_scale * v[channel]);
            }
        }

        self.w_o.apply_into(temp, out);
        for channel in 0..D_MODEL {
            out[channel] += input[channel];
        }
    }
}

/// Per-timestep time-mixer coefficients produced ahead of the recurrence.
struct TimeMixParts {
    r: Vec<f32>,
    k: Vec<f32>,
    v: Vec<f32>,
    w: Vec<f32>,
    a: Vec<f32>,
    k_deformed: Vec<f32>,
    g: Vec<f32>,
    next_v0: Vec<f32>,
}

#[derive(Clone)]
struct TimeState {
    x_shift: Vec<f32>,
    matrix: Vec<f32>,
}

struct ChannelMixer {
    layer_norm: Norm,
    lerp_k: Vec<f32>,
    w_k: Linear,
    w_v: Linear,
}

struct ChannelMixerQueryScratch {
    x: [f32; D_MODEL],
    mixed: [f32; D_MODEL],
    hidden: [f32; MAX_CHANNEL_MIXER_DIM],
    projected: [f32; D_MODEL],
}

impl Default for ChannelMixerQueryScratch {
    fn default() -> Self {
        Self {
            x: [0.0; D_MODEL],
            mixed: [0.0; D_MODEL],
            hidden: [0.0; MAX_CHANNEL_MIXER_DIM],
            projected: [0.0; D_MODEL],
        }
    }
}

impl ChannelMixer {
    fn load(weights: &WeightMap, module_id: usize, layer_id: usize) -> io::Result<Self> {
        let channel_dim = CHANNEL_MIXER_DIMS[module_id];
        let prefix = format!("rwkv_modules.{module_id}.blocks.{layer_id}.channel_mixer");
        Ok(Self {
            layer_norm: weights.layer_norm(&format!("{prefix}.layer_norm"), D_MODEL, 1e-5)?,
            lerp_k: weights.values(&format!("{prefix}.lerp_k"))?,
            w_k: weights.linear(&format!("{prefix}.W_k"), D_MODEL, channel_dim, false)?,
            w_v: weights.linear(&format!("{prefix}.W_v"), channel_dim, D_MODEL, false)?,
        })
    }

    fn run(&self, input: &[f32], state: Option<&Vec<f32>>) -> (Vec<f32>, Vec<f32>) {
        let x = self.layer_norm.apply(input);
        let x_shift = state.map_or(x.as_slice(), |state| state.as_slice());
        let out = self.mix_value(&x, x_shift, input);
        (out, x)
    }

    /// `x` must already be layer-normed; `x_shift` is the previous
    /// timestep's normed input for this stream (or `x` itself when the stream
    /// has no state yet); `input` is the un-normed layer input used for the
    /// residual add.
    fn mix_value(&self, x: &[f32], x_shift: &[f32], input: &[f32]) -> Vec<f32> {
        let mut mixed = [0.0; D_MODEL];
        for channel in 0..D_MODEL {
            mixed[channel] = lerp(x[channel], x_shift[channel], self.lerp_k[channel]);
        }

        let mut k = self.w_k.apply(&mixed);
        for value in &mut k {
            *value = value.max(0.0).powi(2);
        }
        let mut out = self.w_v.apply(&k);
        for channel in 0..D_MODEL {
            out[channel] += input[channel];
        }
        out
    }

    fn run_query_into(
        &self,
        input: &[f32],
        state: Option<&[f32]>,
        out: &mut [f32; D_MODEL],
        scratch: &mut ChannelMixerQueryScratch,
    ) {
        self.layer_norm.apply_into(input, &mut scratch.x);
        let x_shift = state.unwrap_or(&scratch.x);
        for (channel, mixed) in scratch.mixed.iter_mut().enumerate() {
            *mixed = lerp(scratch.x[channel], x_shift[channel], self.lerp_k[channel]);
        }

        let hidden = &mut scratch.hidden[..self.w_k.output];
        self.w_k.apply_into(&scratch.mixed, hidden);
        for value in hidden.iter_mut() {
            *value = value.max(0.0).powi(2);
        }
        self.w_v.apply_into(hidden, &mut scratch.projected);
        for channel in 0..D_MODEL {
            out[channel] = input[channel] + scratch.projected[channel];
        }
    }
}

struct LoraSimple {
    a: Linear,
    b: Linear,
}

impl LoraSimple {
    fn zero(rank: usize) -> Self {
        let linear = |input, output, bias| Linear {
            input,
            output,
            weight_by_input: vec![0.0; input * output],
            bias: if bias { Some(vec![0.0; output]) } else { None },
        };
        Self {
            a: linear(D_MODEL, rank, false),
            b: linear(rank, D_MODEL, true),
        }
    }

    fn load(weights: &WeightMap, prefix: &str, rank: usize) -> io::Result<Self> {
        Ok(Self {
            a: weights.linear(&format!("{prefix}.A"), D_MODEL, rank, false)?,
            b: weights.linear(&format!("{prefix}.B_and_lamb"), rank, D_MODEL, true)?,
        })
    }

    fn apply_sigmoid(&self, input: &[f32]) -> Vec<f32> {
        let mut out = self.b.apply(&self.a.apply(input));
        sigmoid_in_place(&mut out);
        out
    }

    fn apply_sigmoid_into(&self, input: &[f32], hidden: &mut [f32], out: &mut [f32]) {
        let hidden = &mut hidden[..self.a.output];
        self.a.apply_into(input, hidden);
        self.b.apply_into(hidden, out);
        sigmoid_in_place(out);
    }

    fn apply_tanh(&self, input: &[f32]) -> Vec<f32> {
        let mut hidden = self.a.apply(input);
        for value in &mut hidden {
            *value = value.tanh();
        }
        self.b.apply(&hidden)
    }

    fn apply_tanh_into(&self, input: &[f32], hidden: &mut [f32], out: &mut [f32]) {
        let hidden = &mut hidden[..self.a.output];
        self.a.apply_into(input, hidden);
        for value in hidden.iter_mut() {
            *value = value.tanh();
        }
        self.b.apply_into(hidden, out);
    }
}

pub(super) struct Linear {
    pub(super) input: usize,
    pub(super) output: usize,
    pub(super) weight_by_input: Vec<f32>,
    pub(super) bias: Option<Vec<f32>>,
}

impl Linear {
    fn apply(&self, input: &[f32]) -> Vec<f32> {
        let mut out = vec![0.0; self.output];
        self.apply_into(input, &mut out);
        out
    }

    fn apply_into(&self, input: &[f32], out: &mut [f32]) {
        let weight_by_input = &self.weight_by_input;

        debug_assert_eq!(input.len(), self.input);
        debug_assert_eq!(out.len(), self.output);
        if let Some(bias) = &self.bias {
            out.copy_from_slice(bias);
        } else {
            out.fill(0.0);
        }

        for (column, scale) in input.iter().copied().enumerate() {
            if scale == 0.0 {
                continue;
            }
            let weight_column = &weight_by_input[column * self.output..(column + 1) * self.output];
            add_scaled_in_place(out, weight_column, scale);
        }
    }
}

#[inline(always)]
fn add_scaled_in_place(out: &mut [f32], weights: &[f32], scale: f32) {
    debug_assert_eq!(out.len(), weights.len());
    for (output, weight) in out.iter_mut().zip(weights) {
        *output += weight * scale;
    }
}

#[inline(always)]
fn dot_product(left: &[f32], right: &[f32]) -> f32 {
    debug_assert_eq!(left.len(), right.len());
    left.iter()
        .zip(right)
        .map(|(left, right)| left * right)
        .sum()
}

pub(super) struct Norm {
    pub(super) groups: usize,
    pub(super) dim: usize,
    pub(super) eps: f32,
    pub(super) weight: Vec<f32>,
    pub(super) bias: Vec<f32>,
}

impl Norm {
    fn apply(&self, input: &[f32]) -> Vec<f32> {
        let mut out = vec![0.0; self.dim];
        self.apply_into(input, &mut out);
        out
    }

    fn apply_into(&self, input: &[f32], out: &mut [f32]) {
        debug_assert_eq!(input.len(), self.dim);
        debug_assert_eq!(out.len(), self.dim);
        let group_size = self.dim / self.groups;

        for group in 0..self.groups {
            let start = group * group_size;
            let end = start + group_size;
            let values = &input[start..end];
            let mean = values.iter().sum::<f32>() / group_size as f32;
            let variance = values
                .iter()
                .map(|value| {
                    let diff = value - mean;
                    diff * diff
                })
                .sum::<f32>()
                / group_size as f32;
            let scale = (variance + self.eps).sqrt().recip();
            for index in start..end {
                out[index] = (input[index] - mean) * scale * self.weight[index] + self.bias[index];
            }
        }
    }
}

fn single_timestep(
    r: &[f32],
    k: &[f32],
    v: &[f32],
    w: &[f32],
    a: &[f32],
    k_deformed: &[f32],
    state: &[f32],
) -> (Vec<f32>, Vec<f32>) {
    let mut next_state = vec![0.0; HEADS * HEAD_SIZE * HEAD_SIZE];
    let mut out = vec![0.0; D_MODEL];
    single_timestep_into(r, k, v, w, a, k_deformed, state, &mut out, &mut next_state);
    (out, next_state)
}

#[allow(clippy::too_many_arguments)]
fn single_timestep_into(
    r: &[f32],
    k: &[f32],
    v: &[f32],
    w: &[f32],
    a: &[f32],
    k_deformed: &[f32],
    state: &[f32],
    out: &mut [f32],
    next_state: &mut [f32],
) {
    debug_assert_eq!(state.len(), HEADS * HEAD_SIZE * HEAD_SIZE);
    debug_assert_eq!(next_state.len(), HEADS * HEAD_SIZE * HEAD_SIZE);
    debug_assert_eq!(out.len(), D_MODEL);

    for head in 0..HEADS {
        let head_base = head * HEAD_SIZE;
        let matrix_base = head * HEAD_SIZE * HEAD_SIZE;
        let mut state_dot_k = [0.0_f32; HEAD_SIZE];
        let key_deformed = &k_deformed[head_base..head_base + HEAD_SIZE];
        let receptance = &r[head_base..head_base + HEAD_SIZE];

        for (row, value) in state_dot_k.iter_mut().enumerate() {
            let row_start = matrix_base + row * HEAD_SIZE;
            let state_row = &state[row_start..row_start + HEAD_SIZE];
            *value = dot_product(state_row, key_deformed);
        }

        update_recurrence_head(
            &k[head_base..head_base + HEAD_SIZE],
            &v[head_base..head_base + HEAD_SIZE],
            &w[head_base..head_base + HEAD_SIZE],
            &a[head_base..head_base + HEAD_SIZE],
            key_deformed,
            &state[matrix_base..matrix_base + HEAD_SIZE * HEAD_SIZE],
            &state_dot_k,
            &mut next_state[matrix_base..matrix_base + HEAD_SIZE * HEAD_SIZE],
        );

        for row in 0..HEAD_SIZE {
            let row_start = matrix_base + row * HEAD_SIZE;
            let state_row = &next_state[row_start..row_start + HEAD_SIZE];
            out[head_base + row] = dot_product(state_row, receptance);
        }
    }
}

#[allow(clippy::too_many_arguments)]
fn update_recurrence_head(
    k: &[f32],
    v: &[f32],
    w: &[f32],
    a: &[f32],
    key_deformed: &[f32],
    state: &[f32],
    state_dot_k: &[f32; HEAD_SIZE],
    next_state: &mut [f32],
) {
    for row in 0..HEAD_SIZE {
        for column in 0..HEAD_SIZE {
            let old = state[row * HEAD_SIZE + column];
            next_state[row * HEAD_SIZE + column] = old * w[column]
                - state_dot_k[row] * a[column] * key_deformed[column]
                + v[row] * k[column];
        }
    }
}

#[allow(clippy::too_many_arguments)]
fn single_timestep_query_into(
    r: &[f32],
    k: &[f32],
    v: &[f32],
    w: &[f32],
    a: &[f32],
    k_deformed: &[f32],
    state: Option<&[f32]>,
    out: &mut [f32],
    next_row: &mut [f32],
) {
    debug_assert_eq!(out.len(), D_MODEL);
    debug_assert_eq!(next_row.len(), HEAD_SIZE);
    debug_assert!(
        state.is_none() || state.is_some_and(|state| state.len() == HEADS * HEAD_SIZE * HEAD_SIZE)
    );

    for head in 0..HEADS {
        let head_base = head * HEAD_SIZE;
        let matrix_base = head * HEAD_SIZE * HEAD_SIZE;
        let mut state_dot_k = [0.0_f32; HEAD_SIZE];
        let key_deformed = &k_deformed[head_base..head_base + HEAD_SIZE];
        let receptance = &r[head_base..head_base + HEAD_SIZE];

        if let Some(state) = state {
            for (row, value) in state_dot_k.iter_mut().enumerate() {
                let row_start = matrix_base + row * HEAD_SIZE;
                *value = dot_product(&state[row_start..row_start + HEAD_SIZE], key_deformed);
            }
        }

        for row in 0..HEAD_SIZE {
            for (column, next) in next_row.iter_mut().enumerate().take(HEAD_SIZE) {
                let channel = head_base + column;
                let matrix_index = matrix_base + row * HEAD_SIZE + column;
                let old = state.map_or(0.0, |state| state[matrix_index]);
                *next = old * w[channel] - state_dot_k[row] * a[channel] * k_deformed[channel]
                    + v[head_base + row] * k[channel];
            }
            out[head_base + row] = dot_product(next_row, receptance);
        }
    }
}

fn normalize_heads_in_place(values: &mut [f32]) {
    for head in 0..HEADS {
        let start = head * HEAD_SIZE;
        let end = start + HEAD_SIZE;
        let norm = values[start..end]
            .iter()
            .map(|value| value * value)
            .sum::<f32>()
            .sqrt()
            .max(1e-12);
        for value in &mut values[start..end] {
            *value /= norm;
        }
    }
}

fn softmax_into(input: &[f32], out: &mut [f32]) {
    debug_assert_eq!(input.len(), out.len());
    let max = input
        .iter()
        .copied()
        .fold(f32::NEG_INFINITY, |a, b| a.max(b));
    for (output, value) in out.iter_mut().zip(input) {
        *output = (*value - max).exp();
    }
    let sum = out.iter().sum::<f32>();
    for value in out {
        *value /= sum;
    }
}

fn sigmoid_in_place(values: &mut [f32]) {
    for value in values {
        *value = sigmoid(*value);
    }
}

fn sigmoid(value: f32) -> f32 {
    if value >= 0.0 {
        1.0 / (1.0 + (-value).exp())
    } else {
        let exp = value.exp();
        exp / (1.0 + exp)
    }
}

fn softplus(value: f32) -> f32 {
    if value > 20.0 {
        value
    } else if value < -20.0 {
        value.exp()
    } else {
        value.exp().ln_1p()
    }
}

fn silu_in_place(values: &mut [f32]) {
    for value in values {
        *value *= sigmoid(*value);
    }
}

fn relu_in_place(values: &mut [f32]) {
    for value in values {
        *value = value.max(0.0);
    }
}

fn lerp(start: f32, end: f32, weight: f32) -> f32 {
    start + weight * (end - start)
}
