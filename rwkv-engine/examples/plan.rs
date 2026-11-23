//! Prints the model inputs the engine replays for an engine-input JSON file,
//! for the parity reference (parity/reference.rs).

use rwkv_engine::seer;
use serde_json::json;

fn main() {
    let path = std::env::args()
        .nth(1)
        .expect("usage: plan <engine-input.json>");
    let input: seer::Input =
        serde_json::from_slice(&std::fs::read(path).expect("read input")).expect("parse input");
    let plan = seer::plan(&input).expect("plan");
    let out = json!({
        "answers": plan.answers,
        "queries": plan.queries,
        "cards": plan.cards.iter().map(|e| json!({"owner": e.owner, "stack": e.stack, "item": e.item})).collect::<Vec<_>>(),
    });
    println!("{out}");
}
