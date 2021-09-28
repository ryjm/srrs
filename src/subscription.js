import { api } from '~/api';
import { store } from '~/store';

import urbitOb from 'urbit-ob';


export class Subscription {
  start() {
    if (api.authTokens) {
      this.initializeseer();
    } else {
      console.error("~~~ ERROR: Must set api.authTokens before operation ~~~");
    }
  }

  initializeseer() {
    api.bind('/seer-primary', 'PUT', api.authTokens.ship, 'seer',
      this.handleEvent.bind(this),
      this.handleError.bind(this));
  }

  handleEvent(diff) {
    store.handleEvent(diff);
  }

  handleError(err) {
    console.error(err);
    api.bind('/seer-primary', 'PUT', api.authTokens.ship, 'seer',
      this.handleEvent.bind(this),
      this.handleError.bind(this));
  }
}

export let subscription = new Subscription();
