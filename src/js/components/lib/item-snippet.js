import React, { Component } from 'react';
import classnames from 'classnames';

export class ItemSnippet extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <p className="body-regular-400 five-lines"
        style={{WebkitBoxOrient: "vertical"}}>
        {this.props.body}
      </p>
    );
  }
}

