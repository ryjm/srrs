export class ConfigReducer {
    reduce(json, state) {
        const data = json.seer || false;
        if (data) {
            state.inbox = data.inbox;
        }
    }
}
