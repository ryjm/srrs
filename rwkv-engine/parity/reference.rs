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

fn rows(value: &Value) -> Vec<ReviewInput> {
    value.as_array().expect("rows").iter().map(input).collect()
}

fn runtime(weights: &str) -> std::io::Result<RwkvRuntime> {
    RwkvRuntime::load_with_precision(
        weights.into(),
        0.9,
        36_500,
        StatePrecision::F32,
        ModelKind::Sm98,
    )
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = std::env::args().skip(1);
    let usage = "usage: reference <weights> <plan.json> <cases.json>";
    let weights = args.next().ok_or(usage)?;
    let plan: Value = serde_json::from_slice(&std::fs::read(args.next().ok_or(usage)?)?)?;
    let cases: Value = serde_json::from_slice(&std::fs::read(args.next().ok_or(usage)?)?)?;
    let answers = rows(&plan["answers"]);

    // Kernel parity on the candidate's own rows. Steps: the recall the fork
    // predicts just before each answer from the answer's own elapsed time,
    // its historical warm-up. Cards: each card's recall at the fixture's
    // now, after every answer.
    let mut fixture = runtime(&weights)?;
    let steps: Vec<f32> = fixture
        .warm_up_reviews(answers.clone(), true)?
        .into_iter()
        .map(|(_, r)| r)
        .collect();
    let rs = fixture.predict_retrievability_many_from_warm_up(rows(&plan["queries"]))?;
    let cards: Vec<Value> = plan["cards"]
        .as_array()
        .expect("cards")
        .iter()
        .zip(rs)
        .map(|(card, r)| {
            let mut card = card.clone();
            card["r"] = serde_json::json!(r);
            card
        })
        .collect();

    // Kernel parity at show time: before each answer, the live query the
    // loader would have sent for that card when it was shown, as the
    // candidate builds it. A card's first answer has none; it gets the
    // answer-time query, and the test skips it.
    let shown_queries: Vec<ReviewInput> = plan["shown"]
        .as_array()
        .expect("shown")
        .iter()
        .zip(&answers)
        .map(|(shown, answer)| {
            if shown.is_null() {
                let mut query = answer.clone();
                query.is_query = true;
                query.ease = None;
                query.duration_millis = None;
                query
            } else {
                input(shown)
            }
        })
        .collect();
    let shown: Vec<f32> = runtime(&weights)?
        .warm_up_reviews_query(answers, shown_queries, false)?
        .into_iter()
        .map(|(_, r)| r)
        .collect();

    // Translation: the fork on rows written by hand from its own rules, one
    // fresh runtime per case.
    let mut case_rs = Vec::new();
    for case in cases.as_array().expect("cases") {
        let mut fork = runtime(&weights)?;
        fork.warm_up_reviews(rows(&case["answers"]), false)?;
        let r = fork.predict_retrievability_many_from_warm_up(rows(&case["queries"]))?;
        case_rs.push(serde_json::json!({ "name": case["name"], "r": r }));
    }

    let out = serde_json::json!({
        "steps": steps,
        "shown": shown,
        "cards": cards,
        "cases": case_rs,
    });
    println!("{}", serde_json::to_string_pretty(&out)?);
    Ok(())
}
