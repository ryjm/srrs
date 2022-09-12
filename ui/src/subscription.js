import api from './api';
import { store } from './store';

import urbitOb from 'urbit-ob';


export class Subscription {
  start() {
 this.initializeSeer()
  }

  initializeSeer() {
    console.log("initializing seer")
    api.bind('/seer-primary', 'PUT',
      this.handleEvent.bind(this),
      this.handleError.bind(this));
  }

  handleEvent(diff) {
    console.log("handling event: ", diff)
    store.handleEvent(diff);
  }

  handleError(err) {
    console.error("handling error:", err);
    api.bind('/seer-primary', 'PUT', window.ship, 'seer',
      this.handleEvent.bind(this),
      this.handleError.bind(this));
  }
}

export let subscription = new Subscription();
