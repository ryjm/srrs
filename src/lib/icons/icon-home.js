import React, { Component } from "react";

export class IconHome extends Component {
  render() {
    let classes = !!this.props.classes ? this.props.classes : "";
    return (
      <img
        className={"invert-d " + classes}
        src="/~landscape/img/Favicon.png"
        width={16}
        height={16}
      />
    );
  }
}
