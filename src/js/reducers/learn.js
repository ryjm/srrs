import _ from 'lodash';


export class LearnReducer {
    reduce(json, state) {
        let type = _.get(json, 'type', false);
        if (type == 'learn') {
            state.pubs[json.stack].items[json.item].learn = json.data
            state.learn = json.data
        }
    }

}
