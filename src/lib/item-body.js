import React, { Component } from 'react';
import ReactMarkdown from 'react-markdown';

export class ItemBody extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const front = this.props.bodyFront;
    const back = this.props.bodyBack;
    const newFront = front.slice(front.indexOf(';>') + 2);
    const newBack = back.slice(back.indexOf(';>') + 2);
    const toggleStyle = 'v-mid bg-transparent mw6 tl h1 pl4';
    if (this.props.showBack) {
      return (
        <div>
          <div className="md">
            <ReactMarkdown source={newFront} />
          </div>
          <div className="md">
            <ReactMarkdown source={newBack} />
          </div>
          <button
              className={toggleStyle}
              style={{ color: '#2AA779', cursor: 'pointer' }}
              onClick={() => {
 this.props.toggleShowBack();
}}
          >
              Hide
            </button>
        </div>
      );
    } else {
      return (
        <div className="md">
          <ReactMarkdown source={newFront} />
          <button
              className={toggleStyle}
              style={{ color: '#2AA779', cursor: 'pointer' }}
              onClick={() => {
 this.props.toggleShowBack();
}}
          >
              Show
            </button>
        </div>
      );
    }
  }
}

