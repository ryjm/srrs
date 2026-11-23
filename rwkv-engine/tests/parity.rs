//! The engine against the fork's runtime (parity/run.sh writes the fork's
//! numbers to tests/fixtures/reference-r.json). Three kinds of check:
//!
//! - kernel parity: both runtimes on the same model rows, built by this
//!   crate's `seer::plan`, so a wrong translation would pass;
//! - show time: kernel parity on the live query the loader sends when a
//!   card is shown, separate from the answer-time warm-up rows;
//! - translation: %seer inputs through this crate against the fork on rows
//!   written by hand from the fork's rules (tests/fixtures/cases.json).
//!
//! Needs RWKV_WEIGHTS, the weights.bin of tools/build-rwkv-artifact.
//! RWKV_REFERENCE, when set, names fork numbers to use instead of the
//! committed golden; parity/run.sh sets it to the numbers it just made.

use rwkv_engine::seer;
use rwkv_engine::Engine;
use serde::Deserialize;

const REVLOG: &[u8] = include_bytes!("fixtures/revlog.json");

#[derive(Deserialize, PartialEq, Debug)]
struct Row {
    owner: String,
    stack: String,
    item: String,
    r: f64,
}

#[derive(Deserialize)]
struct CaseR {
    name: String,
    r: Vec<f64>,
}

#[derive(Deserialize)]
struct Reference {
    steps: Vec<f64>,
    shown: Vec<f64>,
    cards: Vec<Row>,
    cases: Vec<CaseR>,
}

fn reference() -> Reference {
    let text = match std::env::var("RWKV_REFERENCE") {
        Ok(path) => std::fs::read_to_string(&path).expect("read RWKV_REFERENCE"),
        Err(_) => include_str!("fixtures/reference-r.json").to_owned(),
    };
    serde_json::from_str(&text).expect("reference json")
}

/// Translation: each %seer input of tests/fixtures/cases.json through this
/// crate, against the fork's runtime on that case's rows, which are written
/// by hand from the fork's rules rather than by `seer::plan`.
#[test]
fn translation_matches_the_fork_on_hand_written_rows() {
    #[derive(Deserialize)]
    struct Case {
        name: String,
        input: serde_json::Value,
    }
    let cases: Vec<Case> =
        serde_json::from_str(include_str!("fixtures/cases.json")).expect("cases json");
    let fork = reference().cases;
    assert_eq!(cases.len(), fork.len());
    let mut engine = engine();
    for (case, fork) in cases.iter().zip(&fork) {
        assert_eq!(case.name, fork.name);
        let input = serde_json::to_vec(&case.input).expect("input json");
        let out = seer::predict(&mut engine, &input).expect("predict");
        let native: Vec<f64> = serde_json::from_slice::<Vec<Row>>(&out)
            .expect("output json")
            .into_iter()
            .map(|row| row.r)
            .collect();
        println!("{}: native {native:?}, fork {:?}", case.name, fork.r);
        assert_eq!(native.len(), fork.r.len(), "{}", case.name);
        for (native, fork) in native.iter().zip(&fork.r) {
            assert!(
                native.is_finite() && (native - fork).abs() <= 1e-4,
                "{}: native {native}, fork {fork}",
                case.name
            );
        }
    }
}

fn engine() -> Engine {
    let path = std::env::var("RWKV_WEIGHTS")
        .expect("RWKV_WEIGHTS: path to weights.bin from tools/build-rwkv-artifact");
    Engine::load(&std::fs::read(path).expect("read weights")).expect("load weights")
}

fn predict(engine: &mut Engine) -> Vec<Row> {
    let out = seer::predict(engine, REVLOG).expect("predict");
    serde_json::from_slice(&out).expect("output json")
}

/// Kernel parity: this crate and the fork's runtime on the same rows, which
/// `seer::plan` builds; each card's recall at the fixture's now.
#[test]
fn kernel_final_recall_matches_the_fork() {
    let mut engine = engine();
    let native = predict(&mut engine);
    let fork = reference().cards;
    assert_eq!(native.len(), fork.len());
    let mut max = 0f64;
    for (native, fork) in native.iter().zip(&fork) {
        assert_eq!(
            (&native.owner, &native.stack, &native.item),
            (&fork.owner, &fork.stack, &fork.item)
        );
        assert!((0.0..=1.0).contains(&native.r), "{native:?}");
        max = max.max((native.r - fork.r).abs());
    }
    println!(
        "max |native - fork| R = {max:e} over {} cards",
        native.len()
    );
    assert!(max <= 1e-4, "max |native - fork| R = {max:e}");
}

/// Kernel parity on the fork's historical warm-up: before each answer, the
/// answer-time row with grade and duration cleared, as the fork's bulk
/// replay predicts. Not what the loader asks when a card is shown.
#[test]
fn kernel_warm_up_steps_match_the_fork() {
    let input: seer::Input = serde_json::from_slice(REVLOG).expect("revlog json");
    let plan = seer::plan(&input).expect("plan");
    let mut engine = engine();
    let steps: Vec<f64> = plan
        .answers
        .iter()
        .map(|answer| {
            let mut query = answer.clone();
            query.is_query = true;
            query.ease = None;
            query.duration_millis = None;
            let r = engine.retrievability(&[query])[0];
            engine.answer(answer);
            f64::from(r)
        })
        .collect();
    let fork = reference().steps;
    assert_eq!(steps.len(), fork.len());
    let mut max = 0f64;
    for (index, (native, fork)) in steps.iter().zip(&fork).enumerate() {
        assert!(
            (0.0..=1.0).contains(native) && (native - fork).abs() <= 1e-4,
            "answer {index}: native {native}, fork {fork}"
        );
        max = max.max((native - fork).abs());
    }
    println!(
        "max |native - fork| R before each answer = {max:e} over {} answers",
        steps.len()
    );
}

/// Kernel parity at show time: before each answer, the live query the
/// loader would have sent for that card at its `shown_at`, from its history
/// before the answer. A card's first answer has no query and is skipped.
#[test]
fn kernel_show_time_recall_matches_the_fork() {
    let input: seer::Input = serde_json::from_slice(REVLOG).expect("revlog json");
    let plan = seer::show_time_plan(&input).expect("plan");
    let fork = reference().shown;
    assert_eq!(plan.answers.len(), fork.len());
    let mut engine = engine();
    let mut max = 0f64;
    let mut checked = 0;
    for (index, ((answer, shown), fork)) in
        plan.answers.iter().zip(&plan.shown).zip(&fork).enumerate()
    {
        if let Some(query) = shown {
            let native = f64::from(engine.retrievability(std::slice::from_ref(query))[0]);
            assert!(
                (0.0..=1.0).contains(&native) && (native - fork).abs() <= 1e-4,
                "answer {index}: native {native}, fork {fork}"
            );
            max = max.max((native - fork).abs());
            checked += 1;
        }
        engine.answer(answer);
    }
    println!("max |native - fork| R at show time = {max:e} over {checked} answers");
    assert!(checked > 0);
}

#[test]
fn each_prediction_replays_from_scratch() {
    let mut engine = engine();
    assert_eq!(predict(&mut engine), predict(&mut engine));
}
