import React, { Component } from 'react';
import classnames from 'classnames';
import moment from 'moment';
import { Link } from 'react-router-dom';
import ReactMarkdown from 'react-markdown';

export class ItemBody extends Component {
  constructor(props) {
    super(props)
  }


  render() {
    let front = this.props.bodyFront
    let back = this.props.bodyBack
    let newFront = front.slice(front.indexOf(';>') + 2);
    let newBack = back.slice(back.indexOf(';>') + 2);
    let toggleStyle = "v-mid bg-transparent mw6 tl h1 pl4"
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
              style={{ color: '#2AA779', cursor: "pointer" }}
              onClick={() => { this.props.toggleShowBack() }}>
              Hide
            </button>
        </div>
      );
    }
    else {
      return (
        <div className="md">
          <ReactMarkdown source={newFront} />
          <button
              className={toggleStyle}
              style={{ color: '#2AA779', cursor: "pointer" }}
              onClick={() => { this.props.toggleShowBack() }}>
              Show
            </button>
        </div>
      )
    }
  }
}

