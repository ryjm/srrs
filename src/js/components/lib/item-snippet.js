import React, { Component } from 'react';
import classnames from 'classnames';
import ReactMarkdown from 'react-markdown'

export class ItemSnippet extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <p className="mb1"
        style={{ overflowWrap: "break-word" }}>
        <ReactMarkdown
          unwrapDisallowed
          allowedTypes={['text', 'root', 'break', 'paragraph']}
          source={this.props.body} />
      </p>

    );
  }
}

