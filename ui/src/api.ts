// @ts-nocheck
import React from 'react';
import ReactDOM from 'react-dom';
import { store } from './store';
import Urbit from '@urbit/http-api';
import APIType from './types/API';
import { SeerApiType } from './types/SeerApi';

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

  bind(path, method, ship = window.ship, appl = 'seer', success, fail) {
    this.bindPaths = [...new Set([...this.bindPaths, path])];
    // @ts-ignore TODO window typings
    window.subscriptionId = this.upi.subscribe(ship, appl, path,
      (err) => {
        console.log("error", err);
        fail(err);
      },
      (event) => {
        console.log("event", event);
        success({
          data: event,
          from: {
            ship,
            path
          }
        });
      },
      (quit) => {
        console.log("quit", quit);
        fail(quit);
      });
  }

  action(appl, mark, data) {
    return new Promise((resolve, reject) => {
      this.upi.poke({
        ship: window.ship,
        app: appl,
        mark: mark,
        json: data,
        onError: (err) => {
         console.log(err)
        }});
    });
  }

  fetchStatus(stack, item) {
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
api.seer = new SeerApi()
// api.verbose = true;
// @ts-ignore TODO window typings
window.api = api;

export default api;
