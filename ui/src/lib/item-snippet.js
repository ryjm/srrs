import React, { Component } from 'react';
import ReactMarkdown from 'react-markdown';

export class ItemSnippet extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <div className="mb1"
        style={{ overflowWrap: 'break-word' }}
      >
        <ReactMarkdown
          unwrapDisallowed
          allowedElements={['text', 'root', 'break', 'paragraph']}
          source={this.props.body}
        />
      </div>

    );
  }
}

