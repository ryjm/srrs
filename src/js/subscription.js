import { api } from '/api';
import { store } from '/store';

import urbitOb from 'urbit-ob';


export class Subscription {
  start() {
    if (api.authTokens) {
      this.initializesrrs();
    } else {
      console.error("~~~ ERROR: Must set api.authTokens before operation ~~~");
    }
  }

  initializesrrs() {
    api.bind('/srrs-primary', 'PUT', api.authTokens.ship, 'srrs',
      this.handleEvent.bind(this),
      this.handleError.bind(this));
  }

  handleEvent(diff) {
    store.handleEvent(diff);
  }

  handleError(err) {
    console.error(err);
    api.bind('/srrs-primary', 'PUT', api.authTokens.ship, 'srrs',
      this.handleEvent.bind(this),
      this.handleError.bind(this));
  }
}

export let subscription = new Subscription();
