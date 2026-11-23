//! Maps the %seer revlog (RWKV.md, "Loader") onto the inputs the model was
//! trained on: Anki revlog rows replayed in answer order.

use std::collections::HashMap;

use serde::Deserialize;
use serde::Serialize;

use crate::Engine;
use crate::ReviewInput;

const SECONDS_PER_DAY: i64 = 86_400;
/// Anki's default day rollover, 4:00. The scry carries no time zone, so
/// days roll over at 04:00 UTC.
const ROLLOVER_SECONDS: i64 = 4 * 3_600;
/// Anki caps a revlog answer time at the default maximum answer time, 60 s.
const MAX_DURATION_MILLIS: i64 = 60_000;
/// One deck preset: %seer has no presets.
const PRESET_ID: i64 = 1;

#[derive(Deserialize)]
pub struct Input {
    pub now_ms: i64,
    pub events: Vec<Event>,
}

#[derive(Deserialize)]
pub struct Event {
    pub id: u64,
    pub owner: String,
    pub stack: String,
    pub item: String,
    pub grade: Grade,
    pub kind: Kind,
    pub shown_at: i64,
    pub answered_at: i64,
}

#[derive(Clone, Copy, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Grade {
    Again,
    Hard,
    Good,
    Easy,
}

#[derive(Clone, Copy, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Kind {
    Learn,
    Review,
    Relearn,
    Manual,
}

#[derive(Serialize)]
pub struct Prediction<'a> {
    pub owner: &'a str,
    pub stack: &'a str,
    pub item: &'a str,
    pub r: f32,
}

/// The replay: answers in order, then one query per card at `now_ms`.
pub struct Plan<'a> {
    pub answers: Vec<ReviewInput>,
    pub queries: Vec<ReviewInput>,
    pub cards: Vec<&'a Event>,
}

struct CardHistory {
    id: i64,
    deck: i64,
    last_answered_at: i64,
    reviewed: bool,
    /// In Anki's learning state after its last answer: an `again` before the
    /// card's first `review`. %seer's `again` resets the box to 0, so the
    /// next answer is a `relearn`, state 1 (see `dataset_state`).
    learning: bool,
}

impl CardHistory {
    /// The fork's live query for the card at `now_ms` (scheduler/rwkv.rs,
    /// `rwkv_review_input_state`): elapsed seconds since the last answer,
    /// and scheduler days except in the learning state, which leaves days
    /// unset so the model counts whole days of seconds.
    fn query(&self, now_ms: i64) -> ReviewInput {
        ReviewInput {
            card_id: self.id,
            note_id: Some(self.id),
            deck_id: Some(self.deck),
            preset_id: Some(PRESET_ID),
            is_query: true,
            ease: None,
            duration_millis: None,
            card_type: None,
            day_offset: Some(day(now_ms)),
            current_elapsed_days: (!self.learning)
                .then(|| (day(now_ms) - day(self.last_answered_at)).max(0)),
            current_elapsed_seconds: Some(((now_ms - self.last_answered_at) / 1_000).max(0)),
        }
    }
}

fn day(ms: i64) -> i64 {
    (ms.div_euclid(1_000) - ROLLOVER_SECONDS).div_euclid(SECONDS_PER_DAY)
}

/// The RWKV dataset state of an answer (fork docs/rwkv.MD, "Review Type
/// Contract"). %seer marks every answer after the first on a card that is
/// not in review as `relearn`; before the card's first review that is
/// Anki's later learning answer.
fn dataset_state(kind: Kind, reviewed: bool) -> i64 {
    match kind {
        Kind::Learn => 0,
        Kind::Relearn if !reviewed => 1,
        Kind::Review => 2,
        Kind::Relearn => 3,
        Kind::Manual => 5,
    }
}

/// The replay of `input`. Each card's answers must be one incarnation:
/// a `learn` answer, the fork's learning start, only as the card's first
/// answer, as the scry sends them (RWKV.md, "Replay"). A second learning
/// start would add a second creation sentinel to the card's cumulative
/// elapsed time, outside the model's input domain.
pub fn plan(input: &Input) -> Result<Plan<'_>, String> {
    let mut order: Vec<&Event> = input.events.iter().collect();
    order.sort_by_key(|event| (event.answered_at, event.id));

    let mut cards: HashMap<(&str, &str, &str), CardHistory> = HashMap::new();
    let mut decks: HashMap<(&str, &str), i64> = HashMap::new();
    let mut card_events = Vec::new();
    let mut answers = Vec::with_capacity(order.len());

    for event in order {
        let next_deck = decks.len() as i64 + 1;
        let deck = *decks
            .entry((&event.owner, &event.stack))
            .or_insert(next_deck);
        let next_card = cards.len() as i64 + 1;
        let key = (
            event.owner.as_str(),
            event.stack.as_str(),
            event.item.as_str(),
        );
        let previous = cards.get(&key).map(|card| card.last_answered_at);
        if previous.is_some() && matches!(event.kind, Kind::Learn) {
            return Err(format!(
                "revlog id {}: `learn` after the card's first answer",
                event.id
            ));
        }
        let card = cards.entry(key).or_insert_with(|| {
            card_events.push(event);
            CardHistory {
                id: next_card,
                deck,
                last_answered_at: event.answered_at,
                reviewed: false,
                learning: false,
            }
        });
        let (elapsed_days, elapsed_seconds) = match previous {
            Some(previous) => (
                (day(event.answered_at) - day(previous)).max(0),
                ((event.answered_at - previous) / 1_000).max(0),
            ),
            None => (-1, -1),
        };
        answers.push(ReviewInput {
            card_id: card.id,
            note_id: Some(card.id),
            deck_id: Some(card.deck),
            preset_id: Some(PRESET_ID),
            is_query: false,
            ease: Some(event.grade as u8 + 1),
            duration_millis: Some(
                (event.answered_at - event.shown_at).clamp(0, MAX_DURATION_MILLIS),
            ),
            card_type: Some(dataset_state(event.kind, card.reviewed)),
            day_offset: Some(day(event.answered_at)),
            current_elapsed_days: Some(elapsed_days),
            current_elapsed_seconds: Some(elapsed_seconds),
        });
        card.last_answered_at = event.answered_at;
        card.reviewed |= matches!(event.kind, Kind::Review);
        card.learning = matches!(event.grade, Grade::Again) && !card.reviewed;
    }

    let queries = card_events
        .iter()
        .map(|event| {
            cards[&(
                event.owner.as_str(),
                event.stack.as_str(),
                event.item.as_str(),
            )]
                .query(input.now_ms)
        })
        .collect();

    Ok(Plan {
        answers,
        queries,
        cards: card_events,
    })
}

/// RWKV.md engine input JSON to output JSON, replaying from a fresh state.
pub fn predict(engine: &mut Engine, input: &[u8]) -> Result<Vec<u8>, String> {
    let input: Input = serde_json::from_slice(input).map_err(|err| err.to_string())?;
    let plan = plan(&input)?;
    engine.reset();
    for answer in &plan.answers {
        engine.answer(answer);
    }
    let rs = engine.retrievability(&plan.queries);
    let rows: Vec<Prediction> = plan
        .cards
        .iter()
        .zip(rs)
        .map(|(event, r)| Prediction {
            owner: &event.owner,
            stack: &event.stack,
            item: &event.item,
            r,
        })
        .collect();
    serde_json::to_vec(&rows).map_err(|err| err.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn input(now_ms: i64, events: serde_json::Value) -> Input {
        serde_json::from_value(serde_json::json!({ "now_ms": now_ms, "events": events }))
            .expect("input")
    }

    fn event(id: u64, item: &str, grade: &str, kind: &str, answered_at: i64) -> serde_json::Value {
        serde_json::json!({
            "id": id, "owner": "~zod", "stack": "s1", "item": item, "grade": grade,
            "kind": kind, "shown_at": answered_at - 5_000, "answered_at": answered_at,
        })
    }

    #[test]
    fn a_second_learning_start_for_one_card_is_rejected() {
        let t = 1_782_896_400_000;
        let retired = input(
            t + 600_000,
            serde_json::json!([
                event(0, "a", "good", "learn", t),
                event(1, "b", "easy", "learn", t + 60_000),
                event(2, "a", "again", "learn", t + 180_000),
            ]),
        );
        let err = plan(&retired).err().expect("rejected");
        assert!(err.contains("revlog id 2"), "{err}");
    }
}
