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
        this.setState = () => { };
    }

    setStateHandler(setState) {
        this.setState = setState;
    }

    handleEvent(data) {
        let json = data.data;
        console.log("handling event", json);
        this.initialReducer.reduce(json, this.state);
        this.configReducer.reduce(json, this.state);
        this.updateReducer.reduce(json, this.state);
        this.primaryReducer.reduce(json, this.state);
        this.learnReducer.reduce(data, this.state);
        
        this.setState(this.state);
    }
}

export let store = new Store();
window.store = store;
