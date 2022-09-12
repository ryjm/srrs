//@ts-nocheck
import {
  Add,
  ClearAllOutlined,
  DeleteForeverOutlined,
  ReadMore,
} from "@mui/icons-material";
import { Button, Paper } from "@mui/material";
import React, { Component } from "react";
import { withRouter } from "react-router";
import { Link } from "react-router-dom";
import { marginBottom } from "styled-system";
import { StackNotes } from "../lib/stack-notes";
import { NotFound } from "./not-found";

const NF = withRouter(NotFound);
const BN = withRouter(StackNotes);

export class Stack extends Component {
  constructor(props) {
    super(props);

    this.state = {
      view: "notes",
      awaiting: false,
      itemProps: [],
      stackTitle: "",
      stackHost: "",
      pathData: [],
      temporary: false,
      awaitingSubscribe: false,
      awaitingUnsubscribe: false,
      reviews: this.props.review,
      notFound: false,
    };

    this.subscribe = this.subscribe.bind(this);
    this.unsubscribe = this.unsubscribe.bind(this);
    this.viewSubs = this.viewSubs.bind(this);
    this.viewSettings = this.viewSettings.bind(this);
    this.viewNotes = this.viewNotes.bind(this);
    this.deleteStack = this.deleteStack.bind(this);
    this.reviewStack = this.reviewStack.bind(this);

    this.stack = null;
  }
  handleEvent(diff) {
    console.log("handleEvent");
    if (diff.data.total) {
      const stack = diff.data.total.data;
      this.stack = stack;
      this.setState({
        itemProps: this.buildItems(stack),
        stack: stack,
        stackTitle: stack.info.title,
        stackHost: stack.info.owner,
        awaiting: false,
        pathData: [
          { text: "Home", url: "/seer/review" },
          {
            text: stack.info.title,
            url: `/seer/${stack.info.owner}/${stack.info.filename}`,
          },
        ],
      });

      this.props.setSpinner(false);
    } else if (diff.data.remove) {
      if (diff.data.remove.item) {
        // XX TODO
      } else {
        this.props.history.push("/seer/review");
      }
    }
  }

  handleError(err) {
    this.props.setSpinner(false);
    this.setState({ notFound: true });
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.notFound) {
      return;
    }
    const ship = this.props.ship;
    const stackId = this.props.stackId;
    const stack =
      ship === window.ship
        ? this.props.pubs[stackId] || false
        : this.props.subs[ship][stackId] || false;

    if (!stack && ship === window.ship) {
      this.setState({ notFound: true });
      return;
    } else if (this.stack && !stack) {
      this.props.history.push("/seer/review");
      return;
    }

    this.stack = stack;

    if (this.state.awaitingSubscribe && stack) {
      this.setState({
        temporary: false,
        awaitingSubscribe: false,
      });

      this.props.setSpinner(false);
    }
  }

  componentWillMount() {
    const ship = this.props.ship;
    const stackId = this.props.stackId;
    const stack =
      ship === window.ship
        ? this.props.pubs[stackId] || false
        : this.props.subs[ship][stackId] || false;

    if (!stack && ship === window.ship) {
      this.setState({ notFound: true });
      return;
    }

    const temporary = !stack && ship != window.ship;

    if (temporary) {
      this.setState({
        awaiting: {
          ship: ship,
          stackId: stackId,
        },
        temporary: true,
      });

      this.props.setSpinner(true);

      this.props.api.bind(
        `/stack/${stackId}`,
        "PUT",
        ship,
        "seer",
        this.handleEvent.bind(this),
        this.handleError.bind(this)
      );
    } else {
      this.stack = stack;
    }
  }

  async deleteStack() {
    const del = {
      "delete-stack": {
        who: `~${this.props.ship}`,
        stak: this.props.stackId,
      },
    };
    this.props.setSpinner(true);

    this.setState({
      awaitingDelete: {
        ship: this.props.ship,
        stackId: this.props.stackId,
      },
    });
    /* const id = await this.props.api.bind('/seer-primary', { success: this.handleEvent.bind(this) });
    console.log(id) */
    await this.props.api.action("seer", "seer-action", del);
    this.props.history.push("/seer/review");
  }

  reviewStack() {
    const action = {
      "review-stack": {
        who: `~${this.props.ship}`,
        stak: this.props.stackId,
      },
    };
    this.props.api.action("seer", "seer-action", action);
    this.props.history.push(
      `/seer/~${this.props.ship}/${this.props.stackId}/review`
    );
  }

  buildItems(stack) {
    if (!stack) {
      return [];
    }

    return Object.values(stack.items).map((item) => {
      return this.buildItemPreviewProps(item, stack, true);
    });
  }

  buildItemPreviewProps(item, stack, pinned) {
    return {
      lastReview: item["last-review"],
      learn: item.learn,
      itemTitle: item.content.title,
      itemName: item.name,
      itemBody: item.content.front,
      itemSnippet: item.content.snippet,
      stackTitle: stack.info.title,
      stackName: stack.info.filename,
      author: item.content.author,
      stackOwner: stack.info.owner,
      date: item.content["date-created"],
      pinned: pinned,
    };
  }

  buildData() {
    const ship = this.props.ship;
    const stackId = this.props.stackId;
    const stack =
      ship === window.ship
        ? this.props.pubs[stackId] || false
        : this.props.subs[ship][stackId] || false;

    if (this.state.temporary) {
      return {
        stack: this.state.stack,
        itemProps: this.state.itemProps,
        stackTitle: this.state.stackTitle,
        stackHost: this.state.stackHost,
        pathData: this.state.pathData,
      };
    } else {
      if (!stack) {
        return false;
      }
      return {
        stack: stack,
        itemProps: this.buildItems(stack),
        stackTitle: stack.info.title,
        stackHost: stack.info.owner,
        pathData: [
          { text: "Home", url: "/seer/review" },
          {
            text: stack.info.title,
            url: `/seer/${stack.info.owner}/${stack.info.filename}`,
          },
        ],
      };
    }
  }

  subscribe() {
    const sub = {
      subscribe: {
        who: this.props.ship,
        stack: this.props.stackId,
      },
    };
    this.props.setSpinner(true);
    this.setState({ awaitingSubscribe: true }, () => {
      this.props.api.action("seer", "seer-action", sub);
    });
  }

  unsubscribe() {
    const unsub = {
      unsubscribe: {
        who: this.props.ship,
        stack: this.props.stackId,
      },
    };
    this.props.api.action("seer", "seer-action", unsub);
    this.props.history.push("/seer/review");
  }

  viewSubs() {
    this.setState({ view: "subs" });
  }

  viewSettings() {
    this.setState({ view: "settings" });
  }

  viewNotes() {
    this.setState({ view: "notes" });
  }

  render() {
    const { props } = this;
    const localStack = props.ship === window.ship;

    if (this.state.notFound) {
      return <NF />;
    } else if (this.state.awaiting) {
      return null;
    } else {
      const data = this.buildData();
      let inner = null;
      switch (props.view) {
        case "notes":
          inner = <BN ship={this.props.ship} items={data.itemProps} />;
      }

      return (
        <div className="w-100">
          <div className="w-100 dn-m dn-l dn-xl inter pt4 pb6 f9">
            <Link to="/seer/review">{"<- review"}</Link>
          </div>
          <div
            className="mw9 f9 h-100 w-100 flex"
            style={{ paddingLeft: 16, paddingRight: 16 }}
          >
            <div className="h-100 w-100 pt0 pt8-m pt8-l pt8-xl no-scrollbar">
              <div
                className="flex justify-between"
                style={{ marginBottom: 12 }}
              >
                <Paper className="flex-col z-depth-1 grey lighten-3">
                  <h6>{data.stackTitle}</h6>
                  <span>
                    <span className="mr1">by</span>
                    <span className="gray3 mono" title={data.stackHost}>
                      {data.stackHost}
                    </span>
                  </span>
                </Paper>
                <div className="flex">
                  {localStack && (
                    <Link
                      to={`/seer/~${this.props.ship}/${data.stack.info.filename}/new-item`}
                    >
                      <Button>
                        <Add />
                      </Button>
                    </Link>
                  )}
                  {localStack && (
                    <Button onClick={this.reviewStack}>
                      <ClearAllOutlined></ClearAllOutlined>
                    </Button>
                  )}
                  {localStack && (
                    <Button
                      onClick={this.deleteStack}
                      className="red darken-1 ml4"
                    >
                      <DeleteForeverOutlined />
                    </Button>
                  )}
                </div>
              </div>

              <div className="flex" style={{ marginBottom: 24 }}>
                <Link
                  to={`/seer/${data.stack.info.owner}/${data.stack.info.filename}/review`}
                  className="bb b--gray4 b--gray2-d gray2 pv4 ph2"
                >
                  <Button>
                    <ReadMore />
                  </Button>
                </Link>

                <div
                  className="bb b--gray4 b--gray2-d gray2 pv4 ph2"
                  style={{ flexGrow: 1 }}
                ></div>
              </div>

              <div style={{ height: "auto" }} className="f9 lh-solid flex ml2">
                {inner}
              </div>
            </div>
          </div>
        </div>
      );
    }
  }
}
