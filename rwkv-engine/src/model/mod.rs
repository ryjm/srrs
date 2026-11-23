// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html
// Extracted from rslib/src/rwkv/engine.rs and rslib/src/rwkv/api.rs (Anki
// fork, 17c63ab7f985).

mod features;
mod network;
mod weights;

use std::collections::HashMap;

use features::FeatureState;
use network::ModuleState;
use network::ReviewRetrievabilityScratch;
use network::SrsModel;
use network::SrsState;
use network::SrsStateRef;
use weights::WeightMap;

/// One model input row, with the fork's field names; serialized as the rows
/// the parity reference reads.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct ReviewInput {
    pub card_id: i64,
    pub note_id: Option<i64>,
    pub deck_id: Option<i64>,
    pub preset_id: Option<i64>,
    pub is_query: bool,
    pub ease: Option<u8>,
    pub duration_millis: Option<i64>,
    /// Legacy field name: answered inputs contain the training dataset state.
    pub card_type: Option<i64>,
    pub day_offset: Option<i64>,
    pub current_elapsed_days: Option<i64>,
    pub current_elapsed_seconds: Option<i64>,
}

/// The SM98 instant-only model replaying one collection's review history.
pub struct Engine {
    model: SrsModel,
    features: FeatureState,
    states: ReviewStateMaps,
}

impl Engine {
    /// Parses `ARWKVWEIGHTS1` or `ARWKVWEIGHTS8PC1` weights of the small
    /// architecture with two card layers (SM98).
    pub fn load(weights: &[u8]) -> Result<Engine, String> {
        let weights = WeightMap::parse(weights).map_err(|error| error.to_string())?;
        let mut model = SrsModel::from_weights(weights).map_err(|error| error.to_string())?;
        model.leak_free_inputs = true;
        Ok(Self {
            model,
            features: FeatureState::default(),
            states: ReviewStateMaps::default(),
        })
    }

    /// Forgets every replayed review; the parsed model is kept.
    pub fn reset(&mut self) {
        self.features = FeatureState::default();
        self.states = ReviewStateMaps::default();
    }

    /// Replays one answered review. Inputs without an ease are skipped.
    pub fn answer(&mut self, input: &ReviewInput) {
        if input.ease.is_none() {
            return;
        }
        let features = self.features.features_for(input);
        let next_state = self
            .model
            .review_next_state(&features, self.states.state_ref(input));
        self.features.store_review(input);
        self.states.store(input, next_state);
    }

    /// Instant recall of each query at its elapsed time; does not advance
    /// any state.
    ///
    /// # Panics
    ///
    /// If an input is not a query.
    pub fn retrievability(&self, queries: &[ReviewInput]) -> Vec<f32> {
        assert!(
            queries.iter().all(|input| input.is_query),
            "RWKV batched retrievability prediction only supports query inputs"
        );
        let mut scratch = Box::new(ReviewRetrievabilityScratch::default());
        queries
            .iter()
            .map(|input| {
                let features = self.features.features_for(input);
                self.model.review_retrievability_features(
                    &features,
                    self.states.state_ref(input),
                    &mut scratch,
                )
            })
            .collect()
    }
}

#[derive(Default)]
struct ReviewStateMaps {
    card: HashMap<i64, ModuleState>,
    note: HashMap<i64, ModuleState>,
    deck: HashMap<i64, ModuleState>,
    preset: HashMap<i64, ModuleState>,
    global: Option<ModuleState>,
}

impl ReviewStateMaps {
    fn state_ref(&self, input: &ReviewInput) -> SrsStateRef<'_> {
        SrsStateRef {
            card: self.card.get(&input.card_id),
            note: input.note_id.and_then(|id| self.note.get(&id)),
            deck: input.deck_id.and_then(|id| self.deck.get(&id)),
            preset: input.preset_id.and_then(|id| self.preset.get(&id)),
            global: self.global.as_ref(),
        }
    }

    fn store(&mut self, input: &ReviewInput, state: SrsState) {
        self.card.insert(input.card_id, state.card);
        if let Some(note_id) = input.note_id {
            self.note.insert(note_id, state.note);
        }
        if let Some(deck_id) = input.deck_id {
            self.deck.insert(deck_id, state.deck);
        }
        if let Some(preset_id) = input.preset_id {
            self.preset.insert(preset_id, state.preset);
        }
        self.global = Some(state.global);
    }
}
