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
struct Reference {
    steps: Vec<f64>,
    cards: Vec<Row>,
}

fn reference() -> Reference {
    serde_json::from_str(include_str!("fixtures/reference-r.json")).expect("reference json")
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

#[test]
fn fixture_recall_matches_the_fork_runtime() {
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

#[test]
fn recall_before_every_answer_matches_the_fork_runtime() {
    let input: seer::Input = serde_json::from_slice(REVLOG).expect("revlog json");
    let plan = seer::plan(&input);
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
    let max = steps
        .iter()
        .zip(&fork)
        .map(|(native, fork)| (native - fork).abs())
        .fold(0f64, f64::max);
    println!(
        "max |native - fork| R before each answer = {max:e} over {} answers",
        steps.len()
    );
    assert!(
        max <= 1e-4,
        "max |native - fork| R before each answer = {max:e}"
    );
}

#[test]
fn each_prediction_replays_from_scratch() {
    let mut engine = engine();
    assert_eq!(predict(&mut engine), predict(&mut engine));
}
