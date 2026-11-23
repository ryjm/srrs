use rwkv_engine::seer;
use rwkv_engine::Engine;
use serde::Deserialize;

#[derive(Deserialize, PartialEq, Debug)]
struct Row {
    owner: String,
    stack: String,
    item: String,
    r: f64,
}

fn engine() -> Engine {
    let path = std::env::var("RWKV_WEIGHTS")
        .expect("RWKV_WEIGHTS: path to weights.bin from tools/build-rwkv-artifact");
    Engine::load(&std::fs::read(path).expect("read weights")).expect("load weights")
}

fn predict(engine: &mut Engine) -> Vec<Row> {
    let out = seer::predict(engine, include_bytes!("fixtures/revlog.json")).expect("predict");
    serde_json::from_slice(&out).expect("output json")
}

#[test]
fn fixture_recall_matches_the_fork_runtime() {
    let mut engine = engine();
    let native = predict(&mut engine);
    let fork: Vec<Row> =
        serde_json::from_str(include_str!("fixtures/reference-r.json")).expect("reference json");
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
fn each_prediction_replays_from_scratch() {
    let mut engine = engine();
    assert_eq!(predict(&mut engine), predict(&mut engine));
}
