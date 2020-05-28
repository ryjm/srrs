import React, { Component } from "react";
import classnames from "classnames";
import { ReviewPreview } from "/components/lib/review-preview";
import { withRouter } from "react-router";
import { HeaderMenu } from "/components/lib/header-menu";
import { MessageScreen } from "/components/message-screen";
import { api } from "../api";
import { next } from "sucrase/dist/parser/tokenizer";
import computeSourceMap from "sucrase/dist/computeSourceMap";
import { Link } from 'react-router-dom';

export class Review extends Component {
  constructor(props) {
    super(props);

    this.state = {
      'review-size': 0,
      review: [],
      stack: null
    }
  }

  buildReview() {
    if (!this.props.stack) {
      return this.props.review
    } else {
      return Object.values(this.retrieveStackReview(this.props.stack, window.ship))
        .map(item => {
          return {
            item: item.name,
            stack: this.props.stack,
            who: item.content.author
          }
        })

    }
  }
  buildItemPreviewProps(it, st, who) {
    let item = this.retrieveItem(it, st, who);
    let stack = this.retrieveStack(st, who);
    if (!item) {
      return null;
    }
    return {
      itemTitle: item.content.title,
      itemName: item.name,
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
  retrieveStackReview(stack, who) {
    if (who === window.ship || who.slice(1) === window.ship) {
      if (this.props.pubs[stack]) {
        return this.props.pubs[stack]['review-items'];
      }

    } else {
      return this.props.subs[who][stack]['review-items'];
    }
  }

  shouldComponentUpdate(nextProps, nextState, nextContext) {
    let reviewProps = (nextProps.stack === this.props.stack) && ((nextProps.review.length !== nextState.review.length) || (nextState['review-size'] === nextState.review.length))
    return reviewProps || (nextProps.location.pathname !== this.props.location.pathname)
  }
  componentDidMount() {
    this.setState({
      review: this.props.review,
      'review-size': this.props.review.length
    })
  }
  render() {
    let i = 0
    let stacks = new Set()
    let review = this.buildReview()
    let body = review.map(el => {
      let item = this.buildItemPreviewProps(el.item, el.stack, el.who)
      if (!item) {
        return null
      }
      stacks.add(el.stack)
      i = i + 1
      return (
        <ReviewPreview item={item} key={i} />
      )
    });
    if (review.length == 0) {
      body = <MessageScreen text="Nothing to review!" />;
    }
    let stackLink = el => {
      return {
        pathname: `/~srrs/${el}/review`,
        state: {
          lastPath: this.props.location.pathname,
          lastMatch: this.props.match.path,
          lastParams: this.props.match.params,
        }
      }
    }
    let header = []
    if (this.props.stack) {
      let stackText = `${this.props.stack} ->`
      let reviewText = `<- All`


      header =
        <div className="mt2 flex-auto">
          <Link to={`/~srrs/review`} className="blue3 f9">
            {`${reviewText}`}
          </Link>
          <Link to={`/~srrs/~${window.ship}/${this.props.stack}`} className="blue3 f9 fr">
            {`${stackText}`}
          </Link>
        </div>
    } else if (stacks.size > 0) {
      header =
        [...stacks].map((el, idx) => {
          return <Link key={idx} to={stackLink(el)} className="f9 StackButton ma5 bg-gray4 gray2">{el}</Link>
        })

    } else {
      header =
        Object.values(this.props.pubs).map((el, key) => {
          <div key={key} className="flex-auto">
            <Link to={`/~srrs/${stackLink(el.info.filename)}/review`} className="f9 StackButton ma5 bg-gray4 gray2">{el.info.filename}</Link>
          </div>
        })
    }
    return (

      <div className="overflow-y-scroll"
        style={{ paddingLeft: 16, paddingRight: 16 }}
        onScroll={this.onScroll}
        ref={el => {
          this.scrollElement = el;
        }}>
          <div className="flex flex-wrap">
            {header}
          </div>
        <div className="mw9 f9 h-100"
          style={{ paddingLeft: 10, paddingRight: 10 }}>
          <div className="h-100 pt0 pt4-m pt4-l pt4-xl no-scrollbar">

            <div className="flex flex-wrap" style={{ marginBottom: 15 }}>
              <div className="bb b--gray4 b--gray2-d gray2 ph2"
                style={{ flexGrow: 1 }}></div>
            </div>
            <div className="flex flex-wrap">{body}</div>
          </div>
        </div>
      </div>)
  }
}

