import { InitialReducer } from './reducers/initial';
import { ConfigReducer } from './reducers/config';
import { UpdateReducer } from './reducers/update';
import { LearnReducer } from './reducers/learn';
import { PrimaryReducer } from './reducers/primary';


class Store {
    constructor() {
        this.state = {
            spinner: false,
            ...window.injectedState,
        };

        this.initialReducer = new InitialReducer();
        this.configReducer = new ConfigReducer();
        this.updateReducer = new UpdateReducer();
        this.primaryReducer = new PrimaryReducer();
        this.learnReducer = new LearnReducer();
        this.setState = (s) => { this.state = {...s}; };
    }

    setStateHandler(setState) {
        this.setState = setState;
    }

    handleEvent(data) {
        let json = data.data;
        console.log("handling event", json);
        let updatedState = {...this.state}
        this.initialReducer.reduce(json, updatedState);
        this.configReducer.reduce(json, updatedState);
        this.updateReducer.reduce(json, updatedState);
        this.primaryReducer.reduce(json, updatedState);
        this.learnReducer.reduce(data, updatedState);
        this.state = {...updatedState};
        this.setState(this.state);
    }
}

export let store = new Store();
window.store = store;
