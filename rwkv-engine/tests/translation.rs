//! The %seer adapter against model input rows written by hand from the
//! fork's rules (tests/fixtures/cases.json), not produced by `seer::plan`.
//! Needs no weights.

use rwkv_engine::seer;
use rwkv_engine::ReviewInput;
use serde::Deserialize;

#[derive(Deserialize)]
struct Case {
    name: String,
    input: seer::Input,
    answers: Vec<ReviewInput>,
    queries: Vec<ReviewInput>,
}

#[test]
fn the_adapter_emits_the_rows_the_fork_would() {
    let cases: Vec<Case> =
        serde_json::from_str(include_str!("fixtures/cases.json")).expect("cases json");
    for case in &cases {
        let plan = seer::plan(&case.input).unwrap_or_else(|err| panic!("{}: {err}", case.name));
        assert_eq!(plan.answers, case.answers, "{}: answers", case.name);
        assert_eq!(plan.queries, case.queries, "{}: queries", case.name);
    }
}
