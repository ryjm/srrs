import React from 'react';
import ReactDOM from 'react-dom';

class UrbitApi {
  setAuthTokens(authTokens) {
    this.authTokens = authTokens;
    this.bindPaths = [];
  }
  setChannel(ship, channel) {
    this.ship = ship;
    this.channel = channel;
    this.bindPaths = [];
  }

  bind(path, method, ship = this.authTokens.ship, appl = "seer", success, fail) {
    this.bindPaths = [...new Set([...this.bindPaths, path])];

    window.subscriptionId = this.channel.subscribe(ship, appl, path, 
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

  seer(data) {
    this.action("seer", "json", data);
  }

  action(appl, mark, data) {
    return new Promise((resolve, reject) => {
      this.channel.poke(ship, appl, mark, data,
        (json) => {
          resolve(json);
        }, 
        (err) => {
          reject(err);
        });
    });
  }

  fetchStatus(stack, item) {
    fetch(`/seer/learn/${stack}/${item}.json`)
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
