
import React from 'react';
import ReactDOM from 'react-dom';
import { App } from '~/components/root';
import { api } from '~/api';
import { subscription } from "./subscription";
import Channel from './channel';
import * as util from '~/lib/util';
import _ from 'lodash';
api.setAuthTokens({
  ship: window.ship
});

const channel = new Channel();
api.setChannel(window.ship, channel);
subscription.start();

window.util = util;
window._ = _;

ReactDOM.render((
  <App />
), document.querySelectorAll("#root")[0]);
