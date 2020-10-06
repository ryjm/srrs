export class ConfigReducer {
    reduce(json, state) {
        const data = json.srrs || false;
        if (data) {
            state.inbox = data.inbox;
        }
    }
}
