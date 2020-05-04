import React, { Component } from 'react';
import classnames from 'classnames';

export class TitleSnippet extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (this.props.badge) {
      return (
          <div className="mb1"
            style={{ overflowWrap: "break-word" }}>
            {this.props.title}
        </div>
      );
    } else {
      return (
          <div className="mb1"
            style={{ overflowWrap: "break-word" }}>
            {this.props.title}
          </div>
      );
    }
  }
}

