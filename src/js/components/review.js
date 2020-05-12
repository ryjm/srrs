import React, { Component } from "react";
import classnames from "classnames";
import { ReviewPreview } from "/components/lib/review-preview";
import { withRouter } from "react-router";
import { HeaderMenu } from "/components/lib/header-menu";
import { MessageScreen } from "/components/message-screen";
import { api } from "../api";
import { next } from "sucrase/dist/parser/tokenizer";

export class Review extends Component {
  constructor(props) {
    super(props);

    this.state = {
      'review-size': 0,
      review: []
    }
  }

  buildReview() {
    this.state.review
  }
  buildItemPreviewProps(it, st, who) {
    let item = this.retrieveItem(it, st, who);
    let stack = this.retrieveStack(st, who);
    if (!item) {
      return null;
    }
    return {
      itemTitle: item.content.title,
      itemName: item.content["note-id"],
      itemBody: item.content.front,
      stackTitle: stack.title,
      stackName: stack.filename,
      author: item.content.author,
      stackOwner: stack.owner,
      date: item.content["date-created"],
    };
  }

  retrieveItem(item, stack, who) {
    try {
      if (who === window.ship || who.slice(1) === window.ship) {
        if (this.props.pubs[stack] && this.props.pubs[stack].items[item]) {
          return this.props.pubs[stack].items[item];
        }
      } else {
        return this.props.subs[who][stack].items[item];
      }
    } catch (e) {
      console.log(e)
      return null
    }
  }

  retrieveStack(stack, who) {
    if (who === window.ship || who.slice(1) === window.ship) {
      if (this.props.pubs[stack]) {
        return this.props.pubs[stack].info;
      }

    } else {
      return this.props.subs[who][stack].info;
    }
  }

  shouldComponentUpdate(nextProps, nextState, nextContext) {
    return (nextProps.review.length === nextState.review.length) || (nextState['review-size'] !== nextState.review.length)
  }
  componentDidMount() {
    this.setState({review: this.props.review, 'review-size': this.props.review.length})
  }
  render() {
    let i = 0
    let body = this.state.review.map(el => {
      let item = this.buildItemPreviewProps(el.item, el.stack, el.who)
      i = i + 1
      return (
        <ReviewPreview item={item} key={i} />
      )
    });
    if (this.props.review.length == 0) {
      body = <MessageScreen text="Nothing to review!" />;
    }

    return (
      <div className="overflow-y-scroll"
        style={{ paddingLeft: 16, paddingRight: 16 }}
        onScroll={this.onScroll}
        ref={el => {
          this.scrollElement = el;
        }}>
        <div className="center mw6 f9 h-100"
          style={{ paddingLeft: 16, paddingRight: 16 }}>
          <div className="h-100 pt0 pt8-m pt8-l pt8-xl no-scrollbar">

            <div className="flex-col">{body}</div>
          </div>
        </div>
      </div>)
  }
}

