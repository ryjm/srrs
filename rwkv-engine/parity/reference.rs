// Built as a binary of the fork's own `anki` crate at the pinned commit
// (parity/run.sh copies it into rslib/src/bin/), so the reference numbers
// come from the fork's runtime, not from this crate.

use anki::rwkv::ModelKind;
use anki::rwkv::ReviewInput;
use anki::rwkv::RwkvRuntime;
use anki::rwkv::StatePrecision;
use serde_json::Value;

fn input(row: &Value) -> ReviewInput {
    let int = |key: &str| row[key].as_i64();
    ReviewInput {
        card_id: int("card_id").expect("card_id"),
        note_id: int("note_id"),
        deck_id: int("deck_id"),
        preset_id: int("preset_id"),
        is_query: row["is_query"].as_bool().expect("is_query"),
        ease: int("ease").map(|ease| ease as u8),
        duration_millis: int("duration_millis"),
        card_type: int("card_type"),
        day_offset: int("day_offset"),
        current_elapsed_days: int("current_elapsed_days"),
        current_elapsed_seconds: int("current_elapsed_seconds"),
        target_retentions: [None; 4],
        enforce_grade_order: false,
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = std::env::args().skip(1);
    let weights = args.next().ok_or("usage: reference <weights> <plan.json>")?;
    let plan: Value = serde_json::from_slice(&std::fs::read(args.next().ok_or("plan.json")?)?)?;
    let rows = |key: &str| plan[key].as_array().unwrap().iter().map(input).collect::<Vec<_>>();
    let mut runtime = RwkvRuntime::load_with_precision(
        weights.into(),
        0.9,
        36_500,
        StatePrecision::F32,
        ModelKind::Sm98,
    )?;
    // The recall the fork predicts just before each answer, from the answer's
    // own elapsed time: checks every replay step, not only the final state.
    let steps: Vec<f32> = runtime
        .warm_up_reviews(rows("answers"), true)?
        .into_iter()
        .map(|(_, r)| r)
        .collect();
    let rs = runtime.predict_retrievability_many_from_warm_up(rows("queries"))?;
    let cards: Vec<Value> = plan["cards"]
        .as_array()
        .unwrap()
        .iter()
        .zip(rs)
        .map(|(card, r)| {
            let mut card = card.clone();
            card["r"] = serde_json::json!(r);
            card
        })
        .collect();
    let out = serde_json::json!({ "steps": steps, "cards": cards });
    println!("{}", serde_json::to_string_pretty(&out)?);
    Ok(())
}
