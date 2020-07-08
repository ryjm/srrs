export class LearnReducer {
    reduce(json, state) {
        const type = json.type || false;
        if (type == 'learn') {
            state.pubs[json.stack].items[json.item].learn = json.data
            state.learn = json.data
        }
    }

}
