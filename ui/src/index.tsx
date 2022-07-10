import React from "react";
import ReactDOM from "react-dom";
import api from "./api";
import util from "./lib/util";
import { App } from "./components/root";
import { subscription } from "./subscription";
// @ts-ignore TODO window typings
window.util = util;
// @ts-ignore TODO window typings
window._ = _;
// @ts-ignore TODO window typings
window.api = api

subscription.initializeSeer();
// @ts-ignore TODO window typings
window.subscription = subscription;

console.log(subscription)
ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById('root')
);
