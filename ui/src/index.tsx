import React from "react";
import ReactDOM from "react-dom";
import api from "./api";
import util from "./lib/util";
import { App } from "./components/root";// @ts-ignore TODO window typings
import { createRoot } from 'react-dom/client';
// @ts-ignore TODO window typings
window.util = util;
// @ts-ignore TODO window typings
window._ = _;
// @ts-ignore TODO window typings
window.api = api
const root = createRoot(document.getElementById("root"));
root.render(<App />);

