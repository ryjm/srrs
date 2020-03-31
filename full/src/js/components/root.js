import React, { Component } from 'react';
import { BrowserRouter, Route } from "react-router-dom";
import classnames from 'classnames';
import _ from 'lodash';
import { HeaderBar } from "./lib/header-bar.js"


export class Root extends Component {
  constructor(props) {
    super(props);
  }

  render() {

    return (
      <BrowserRouter>
        <div>
        <HeaderBar/>
        <Route exact path="/~srrs" render={ () => {
          return (
            <div className="pa3 w-100">
              <h1 className="mt0 f2">srrs</h1>
              <p className="lh-copy measure pt3">Welcome to srrs.</p>
              <p className="lh-copy measure pt3"></p>
            </div>
          )}}
        />
        </div>
      </BrowserRouter>
    )
  }
}

