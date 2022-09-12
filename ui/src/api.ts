// @ts-nocheck
import { store } from './store';
import Urbit from '@urbit/http-api';
import APIType from './types/API';

function createInstance<T extends APIType>(c: new () => T): T {
  return new c();
}

class SeerApi {
  authTokens: any;
  bindPaths: any[] = [];
  ship: any;
  channel: any;
  upi: Urbit = new Urbit('', '', 'seer');
  setAuthTokens(authTokens) {
    this.authTokens = authTokens;
    this.bindPaths = [];
  }
  setChannel(ship, channel) {
    this.ship = ship;
    this.channel = channel;
    this.bindPaths = [];
  }
  createSubscription(app: string, path: string, e: (data: any) => void): SubscriptionRequestInterface {
    const request = {
      app,
      path,
      event: e,
      err: () => console.warn('SUBSCRIPTION ERROR'),
      quit: () => {
        throw new Error('subscription clogged');
      }
    };
    // TODO: err, quit handling (resubscribe?)
    return request;
  }
  bind(path, method?, ship = window.ship, appl = 'seer', success: (data: any) => void, fail?: () => void) {
    this.bindPaths = [...new Set([...this.bindPaths, path])];
    // @ts-ignore TODO window typings
    return this.upi.subscribe(this.createSubscription(appl, path,
      (event) => {
        console.log("event", event);
        store.handleEvent({
          data: event,
          from: {
            ship,
            path
          }
        });
      },
      (err) => {
        console.log("error", err);
        if (fail) fail(err);
      }))
  }

  action(appl, mark, data): Promise<number> {
      this.upi.poke({
        app: appl,
        mark: mark,
        json: data,
        onSuccess: () => {
          console.log('success')
        },
        onError: (err) => {
         console.log(err)
        }
    });
  }

  fetchStatus(stack, item): Promise<any> {
    fetch(`/seer/learn/${stack}/${item}.json`)
    .then(response => response.json())
    .then((json) => {
      store.handleEvent({
        type: 'learn',
        data: json,
        stack: stack,
        item: item
      });
    });
  }
  fetchStacks() {
    fetch(`/seer/stacks.json`)
    .then(response => response.json())
    .then((json) => {
      store.handleEvent({
        data: json
      });
    });
  }
    sidebarToggle() {
    let sidebarBoolean = true;
    if (store.state.sidebarShown === true) {
      sidebarBoolean = false;
    }
    store.handleEvent({
      type: 'local',
      data: {
        'sidebarToggle': sidebarBoolean
      }
    });
  }
}

// @ts-ignore TODO window typings
const api = createInstance(SeerApi)
// @ts-ignore TODO window typings
api.ship = window.ship;
api.upi = new Urbit('', '', 'seer')

api.upi.ship = window.ship;
api.seer = new SeerApi()
api.seer.upi.ship = window.ship;
// api.verbose = true;
// @ts-ignore TODO window typings
api.bind('/seer-primary');


window.api = api;

export default api;
