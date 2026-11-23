//! The native engine on an engine-input JSON file: prints the engine output.

use rwkv_engine::seer;
use rwkv_engine::Engine;

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let [weights, input] = args.as_slice() else {
        panic!("usage: predict <weights.bin> <engine-input.json>");
    };
    let mut engine = Engine::load(&std::fs::read(weights).expect("read weights")).expect("load");
    let out =
        seer::predict(&mut engine, &std::fs::read(input).expect("read input")).expect("predict");
    println!("{}", String::from_utf8(out).expect("utf-8"));
}
