import React, { Component } from "react";
import ReviewPreview from "../lib/review-preview";
import { MessageScreen } from "./message-screen";
import { Link } from "react-router-dom";
import { Chip, Button } from "@mui/material";
import { ArrowBack, Article } from "@mui/icons-material";

export class Review extends Component {
  constructor(props) {
    super(props);

    this.state = {
      "review-size": 0,
      review: [],
      stack: null,
    };
  }

  buildReview() {
    if (!this.props.stack) {
      return this.props.review;
    } else {
      return Object.values(
        this.retrieveStackReview(this.props.stack, this.props.who.slice(1))
      ).map((item) => {
        return {
          item: item.name,
          stack: this.props.stack,
          who: item.content.author,
        };
      });
    }
  }
  buildItemPreviewProps(it, st, who) {
    const item = this.retrieveItem(it, st, who);
    const stack = this.retrieveStack(st, who);
    if (!item) {
      return null;
    }
    return {
      content: item.content,
      lastReview: item["last-review"],
      learn: item.learn,
      itemTitle: item.content.title,
      itemName: item.name,
      itemSnippet: item.content.snippet,
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
      return null;
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
        return this.props.pubs[stack]["review-items"];
      }
    } else {
      return this.props.subs[who][stack]["review-items"];
    }
  }

  shouldComponentUpdate(nextProps, nextState, nextContext) {
    const reviewProps =
      nextProps.stack === this.props.stack &&
      (nextProps.review.length !== nextState.review.length ||
        nextState["review-size"] === nextState.review.length);
    return (
      reviewProps ||
      nextProps.location.pathname !== this.props.location.pathname
    );
  }
  componentDidMount() {
    this.setState({
      review: this.props.review,
      "review-size": this.props.review.length,
    });
  }
  render() {
    let i = 0;
    const stacks = new Set();
    const review = this.buildReview();
    let body = review.map((el) => {
      const item = this.buildItemPreviewProps(
        el.item,
        el.stack,
        el.who.slice(1)
      );
      if (!item) {
        return null;
      }
      stacks.add(el.stack);
      i = i + 1;
      return (
        <ReviewPreview
          item={item}
          key={i}
          idx={i}
          next={review[i]}
          reviews={review}
        />
      );
    });
    if (review.length == 0) {
      body = <MessageScreen text="Nothing to review!" />;
    }
    const stackLink = (el) => {
      return {
        pathname: `/seer/~${window.ship}/${el}/review`,
        state: {
          lastPath: this.props.location.pathname,
          lastMatch: this.props.match.path,
          lastParams: this.props.match.params,
        },
      };
    };
    let header = [];
    if (this.props.stack) {
      const stackText = `${this.props.stack} ->`;
      const reviewText = "<- all";

      header = (
        <div className="mt2 flex-auto ph2" style={{ overflow: "hidden" }}>
          <Link to={"/seer/review"} className="blue3 f9">
            <ArrowBack />
          </Link>
          <Link
            to={`/seer/~${window.ship}/${this.props.stack}`}
            className="f9 fr"
          >
            <Article />
          </Link>
        </div>
      );
    } else if (stacks.size > 0) {
      header = [...stacks].map((el, idx) => {
        return (
          <Link key={idx} to={stackLink(el)} className="f9 gray2 ma5">
           <Button variant="outlined" color="primary" size="small" startIcon={<Article />}>{el}</Button>
          </Link>
        );
      });
    } else {
      header = Object.values(this.props.pubs).map((el, key) => {
        <div>
          <Link
            key={key}
            to={`/seer/${el.info.owner}/${stackLink(el.info.filename)}/review`}
            className="f9 StackButton ma5 bg-gray4 gray2 flex-auto"
          >
            {el.info.filename}
          </Link>
        </div>;
      });
    }
    return (
      <div
        className="h-100 w-100"
        style={{ paddingLeft: 16 }}
        /*  onScroll={this.onScroll}
       ref={(el) => {
         this.scrollElement = el;
       }} */
      >
        <div className="pt4 flex-wrap no-scrollbar">{header}</div>
        <div
          className="mw9 f9 h-100"
          style={{ paddingLeft: 10, paddingRight: 10 }}
        >
          <div className="h-100 pt0 pt4-m pt4-l pt4-xl">
            <div className="flex flex-wrap" style={{ marginBottom: 15 }}>
              <div className="bb ph2" style={{ flexGrow: 1 }}></div>
            </div>

            <div className="flex flex-wrap f9 mb2 p2">{body}</div>
          </div>
        </div>
      </div>
    );
  }
}
