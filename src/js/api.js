import React from 'react';
import ReactDOM from 'react-dom';
import _ from 'lodash';

class UrbitApi {
  setAuthTokens(authTokens) {
    this.authTokens = authTokens;
    this.bindPaths = [];
  }

  bind(path, method, ship = this.authTokens.ship, appl = "srrs", success, fail) {
    this.bindPaths = _.uniq([...this.bindPaths, path]);

    window.subscriptionId = window.urb.subscribe(ship, appl, path, 
      (err) => {
        fail(err);
      },
      (event) => {
        success({
          data: event,
          from: {
            ship,
            path
          }
        });
      },
      (err) => {
        fail(err);
      });
  }

  srrs(data) {
    this.action("srrs", "json", data);
  }

  action(appl, mark, data) {
    return new Promise((resolve, reject) => {
      window.urb.poke(ship, appl, mark, data,
        (json) => {
          resolve(json);
        }, 
        (err) => {
          reject(err);
        });
    });
  }

  fetchStatus(stack, item) {
    fetch(`/~srrs/learn/${stack}/${item}.json`)
    .then((response) => response.json())
    .then((json) => {
      store.handleEvent({
        type: 'learn',
        data: json,
        stack: stack,
        item: item,
      });
    });
  }
    sidebarToggle() {
    let sidebarBoolean = true;
    if (store.state.sidebarShown === true) {
      sidebarBoolean = false;
    }
    store.handleEvent({
      type: "local",
      data: {
        'sidebarToggle': sidebarBoolean
      }
    });
  }

}
export let api = new UrbitApi();
window.api = api;
