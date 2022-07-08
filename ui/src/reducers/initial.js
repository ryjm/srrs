export class InitialReducer {
    reduce(json, state) {
        const data = json.initial || false;
        if (data) {
            state.inbox = data.inbox;
        }
    }
}
