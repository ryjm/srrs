//! Prints the model inputs the engine replays for an engine-input JSON file,
//! for the parity reference (parity/reference.rs).

use rwkv_engine::seer;
use rwkv_engine::ReviewInput;
use serde_json::json;
use serde_json::Value;

fn row(input: &ReviewInput) -> Value {
    json!({
        "card_id": input.card_id,
        "note_id": input.note_id,
        "deck_id": input.deck_id,
        "preset_id": input.preset_id,
        "is_query": input.is_query,
        "ease": input.ease,
        "duration_millis": input.duration_millis,
        "card_type": input.card_type,
        "day_offset": input.day_offset,
        "current_elapsed_days": input.current_elapsed_days,
        "current_elapsed_seconds": input.current_elapsed_seconds,
    })
}

fn main() {
    let path = std::env::args()
        .nth(1)
        .expect("usage: plan <engine-input.json>");
    let input: seer::Input =
        serde_json::from_slice(&std::fs::read(path).expect("read input")).expect("parse input");
    let plan = seer::plan(&input);
    let out = json!({
        "answers": plan.answers.iter().map(row).collect::<Vec<_>>(),
        "queries": plan.queries.iter().map(row).collect::<Vec<_>>(),
        "cards": plan.cards.iter().map(|e| json!({"owner": e.owner, "stack": e.stack, "item": e.item})).collect::<Vec<_>>(),
    });
    println!("{out}");
}
