import React, { Component } from 'react';
import { Route, Link } from 'react-router-dom';

export class StackEntry extends Component {
  render() {
    let { props } = this;

    let selectedClass = (props.selected) ? "bg-gray5 bg-gray1-d c-default" : "pointer hover-bg-gray5 hover-bg-gray1-d";

    return (
      <Link
      to={"/~srrs/" + props.path}>
        <div className={"w-100 v-mid f9 ph4 pv1 " + selectedClass}>
          <p className="dib f9">{props.title}</p>
        </div>
      </Link>
    );
  }
}

export default StackEntry
