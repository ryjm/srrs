import React, { Component } from "react";
import moment from "moment";
import { Link } from "react-router-dom";
import { ItemBody } from "../lib/item-body";
import { EditItem } from "./edit-item";
import { Recall } from "./recall";
import { NotFound } from "./not-found";
import { withRouter } from "react-router";
import momentConfig from "../config/moment";
import { isNull } from "lodash";

const NF = withRouter(NotFound);

export class Item extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale("en", momentConfig);

    this.state = {
      mode: "view",
      title: "",
      bodyFront: "",
      bodyBack: "",
      reviews: this.props.review,
      learn: [],
      awaitingEdit: false,
      awaitingGrade: false,
      awaitingLoad: false,
      awaitingDelete: false,
      recallGrade: null,
      submit: false,
      ship: this.props.ship,
      stackId: this.props.stackId,
      itemId: this.props.itemId,
      stack: null,
      item: null,
      pathData: [],
      temporary: false,
      notFound: false,
      next: null,
    };
    
    if (this.props.location.state) {
      const mode = this.props.location.state.mode;
      /* this.state.reviews = this.props.location.state.reviews; */
      if (mode) {
        this.state.mode = mode;
      }
    }

    this.editItem = this.editItem.bind(this);
    this.deleteItem = this.deleteItem.bind(this);
    this.titleChange = this.titleChange.bind(this);
    this.gradeItem = this.gradeItem.bind(this);
    this.setGrade = this.setGrade.bind(this);
    this.saveGrade = this.saveGrade.bind(this);
    this.toggleAdvanced = this.toggleAdvanced.bind(this);
    this.toggleShowBack = this.toggleShowBack.bind(this);

    const { ship, stackId, itemId } = this.props;
    const locstate = this.props.location.state
      ? this.props.location.state
      : undefined;
    
    const nextId =
      locstate && locstate.next ? this.props.location.state.next.item : this.randomReview().item;
      
    if (ship !== window.ship) {
      const stack = this.props.subs[ship][stackId];

      if (stack) {
        const item = stack.items[itemId];
        const learn = item.learn;
        const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
        const itemUrl = `${stackUrl}/${item.name}`;
        const next = item.name === nextId ? `${stackUrl}/${this.randomReview().item}` : `${stackUrl}/${nextId}`;
        this.state = {
          ...this.state,
          title: item.content.title,
          bodyFront: item.content.front,
          bodyBack: item.content.back,
          stack,
          item,
          learn,
          next,
          pathData: [
            { text: "Home", url: "/seer/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.title, url: itemUrl },
          ],
        };
      } else {
        this.state = {
          ...this.state,
          temporary: true,
          awaitingLoad: {
            ship: ship,
            stackId: stackId,
            itemId: itemId,
          },
        };
      }
    } else {
      const stack = this.props.pubs[stackId];
      const item = stack.items[itemId];
      const learn = item.learn;

      if (!stack || !item) {
        this.state = { ...this.state, ...{ notFound: true } };
        return;
      } else {
        const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
        const itemUrl = `${stackUrl}/${item.name}`;
        const next = `${stackUrl}/${nextId}`;
        this.state = {
          ...this.state,
          title: item.content.title,
          bodyFront: item.content.front,
          bodyBack: item.content.back,
          next,
          stack: stack,
          item: item,
          learn: learn,
          pathData: [
            { text: "Home", url: "/seer/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.content.title, url: itemUrl },
          ],
        };
      }
    }
  }
  getNextReview(ship, stackId, itemId) {
  const locstate = this.props.location.state
    const next =
      locstate && locstate.next ? locstate.next : this.randomReview();
      
      const stack = this.props.pubs[next.stack];

      const item = stack.items[next.item];
      const learn = item.learn;
      const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
      const itemUrl = `${stackUrl}/${item.name}`;
      if (this.state.reviews.length === 1) return itemUrl;
      return item.name !== this.state.item.name ? itemUrl : `${stackUrl}/${this.randomReview().item}`  
    }
  randomReview() { 
    return this.state.reviews[Math.floor(Math.random()*this.state.reviews.length)]; }
  editItem() {
    this.setState({ mode: "edit" });
  }

  gradeItem() {
    this.setState({ mode: "grade" });
  }
  setGrade(value) {
    this.setState({ recallGrade: value });
  }
  toggleAdvanced() {
    if (this.state.mode == "advanced") {
      this.setState({ mode: "view" });
    } else {
      this.setState({ mode: "advanced" });
    }
  }
  toggleShowBack() {
    if (this.state.showBack) {
      this.setState({ showBack: false });
    } else {
      this.setState({ showBack: true });
    }
  }

  saveGrade(value) {
    this.props.setSpinner(true);
    this.setGrade(value);
    const data = {
      "answered-item": {
        owner: this.props.match.params.ship,
        stak: this.props.stackId,
        item: this.props.itemId,
        answer: value,
      },
    };
    this.setState(
      {
        awaitingGrade: {
          ship: this.state.ship,
          stackId: this.props.stackId,
          itemId: this.props.itemId,
          answer: value,
        },
      },
      () => {
        this.props.api.action("seer", "seer-action", data);
      }
    );
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.notFound) return;

    const { ship, stackId, itemId } = this.props;

    const oldItem = prevState.item;
    const oldStack = prevState.stack;

    const stack =
      ship === window.ship
        ? this.props.pubs[stackId]
        : this.props.subs[ship][stackId];
    const item = stack.items[itemId];
    const learn = item ? item.learn : null;

    if (this.state.learn !== learn) {
      this.setState({ learn });
    }
    if (this.state.awaitingDelete && item === false && oldItem) {
      this.props.setSpinner(false);
      const redirect = `/seer/~${this.props.ship}/${this.props.stackId}`;
      this.props.history.push(redirect);
      return;
    }

    if (!stack || !item) {
      this.setState({ notFound: true });
      return;
    }

    if (
      this.state.awaitingEdit &&
      (item.content.title != oldItem.title ||
        item.content.front != oldItem.content.front ||
        item.content.back != oldItem.content.back)
    ) {
      const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
      const itemUrl = `${stackUrl}/${item.name}`;

      this.setState({
        mode: "view",
        title: item.content.title,
        bodyFront: item.content.front,
        bodyBack: item.content.back,
        awaitingEdit: false,
        item: item,
        pathData: [
          { text: "Home", url: "/seer/review" },
          { text: stack.info.title, url: stackUrl },
          { text: item.content.title, url: itemUrl },
        ],
      });

      this.props.setSpinner(false);

      const read = {
        read: {
          who: ship,
          stak: stackId,
          item: itemId,
        },
      };
      this.props.api.action("seer", "seer-action", read);
    }

    if (this.state.awaitingGrade) {
      const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
      const itemUrl = `${stackUrl}/${item.name}`;

      let redirect = '/seer/review'
      if (this.state.mode === "review") {
        redirect = this.getNextReview(ship, stackId, itemId);
      } else redirect = this.state.next;
      this.setState(
        {
          recallGrade: this.state.awaitingGrade.answer,
          item: item,
        },
        () => {
          this.props.api.fetchStatus(stack.info.filename, item.name);
        }
      );
      this.setState(
        {
          awaitingGrade: false,
          mode: this.state.mode === "review" ? "review" : "view",
        },
        () => {
          this.props.history.push(redirect);
        }
      );
    }
    if (!this.state.temporary) {
      if (oldItem != item) {
        const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
        const itemUrl = `${stackUrl}/${item.name}`;
        const locstate = this.props.location.state;
        this.setState({
          item: item,
          title: item.content.title,
          bodyFront: item.content.front,
          bodyBack: item.content.back,
          next:
            locstate && locstate.next
              ? `${stackUrl}/${this.props.location.state.next.item}`
              : this.state.next,
          pathData: [
            { text: "Home", url: "/seer/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.content.title, url: itemUrl },
          ],
        });

        const read = {
          read: {
            who: ship,
            stak: stackId,
            item: itemId,
          },
        };
        this.props.api.action("seer", "seer-action", read);
      }

      if (oldStack != stack) {
        this.setState({ stack: stack });
      }
    }
  }

  deleteItem() {
    const del = {
      "delete-item": {
        stak: this.props.stackId,
        item: this.props.itemId,
      },
    };
    this.props.setSpinner(true);
    this.setState(
      {
        awaitingDelete: {
          ship: this.props.ship,
          stackId: this.props.stackId,
          itemId: this.props.itemId,
        },
      },
      () => {
        this.props.api.action("seer", "seer-action", del).then(() => {
          const redirect = `/seer/~${this.props.ship}/${this.props.stackId}`;
          this.props.history.push(redirect);
        });
      }
    );
  }

  titleChange(evt) {
    this.setState({ title: evt.target.value });
  }

  gradeChange(evt) {
    this.setState({ recallGrade: evt.target.value });
  }

  render() {
    const { props, state } = this;
    const adminEnabled = this.props.ship === window.ship;

    if (this.state.notFound) return <NF />;
    if (this.state.awaitingLoad) return null;
    if (this.state.awaitingEdit) return null;

    if (
      this.state.mode == "review" ||
      this.state.mode == "view" ||
      this.state.mode == "grade" ||
      this.state.mode == "advanced"
    ) {
      const title = this.state.item.content.title;
      const stackTitle = this.props.stackId;
      const host = this.state.stack.info.owner;
      const locstate = this.props.location.state
        ? this.props.location.state
        : null;
      const next =
        this.state.next === this.props.itemId
          ? this.props.location.state.next
          : this.state.next;
      let nextUrl = null;
      if (locstate && locstate.next) {
        const nextStack = locstate.next.stack;
        const nextOwner = locstate.next.who;
        nextUrl = `/seer/${nextOwner}/${nextStack}/${locstate.next.item}`;
      }
      const idx = locstate ? locstate.idx : 0;
      const reviews = this.state.reviews;
      return (
        <div
          className="center mw6 f9 h-100"
          style={{ paddingLeft: 16, paddingRight: 16 }}
        >
          <div className="h-100 pt2 pt8-m pt8-l pt8-xl no-scrollbar">
            <div className="flex justify-between" style={{ marginBottom: 32 }}>
              <div className="flex-col">
                <div className="mb1">{title}</div>
                <span>
                  <span className="gray3 mr1">by</span>
                  <span className={"mono"} title={host}>
                    {host}
                  </span>
                </span>
                <Link to={`/seer/${host}/${stackTitle}`} className="blue3 ml2">
                  {`<- ${stackTitle}`}
                </Link>
              </div>
              <div className="flex">
                <Link
                  to={`/seer/${host}/${stackTitle}/new-item`}
                  className="ml3 StackButton bg-light-green green2"
                >
                  new item
                </Link>
              </div>
              <Link
                to={{
                  pathname: nextUrl ? nextUrl : next,
                  state: {
                    next: reviews ? reviews[idx + 1] : next,
                    idx: idx + 1,
                    mode: "review",
                    prevPath: location.pathname,
                  },
                }}
                className="ml3 StackButton bg-light-green green3"
              >
                next
              </Link>
            </div>
            <Recall
              enabled={adminEnabled}
              mode={this.state.mode}
              editItem={this.editItem}
              deleteItem={this.deleteItem}
              gradeItem={this.gradeItem}
              setGrade={this.setGrade}
              saveGrade={this.saveGrade}
              toggleAdvanced={this.toggleAdvanced}
              learn={this.state.learn}
              host={host}
            />

            <ItemBody
              bodyFront={this.state.item.content.front}
              bodyBack={this.state.item.content.back}
              showBack={this.state.showBack}
              toggleShowBack={this.toggleShowBack}
            />
          </div>
        </div>
      );
    } else if (this.state.mode == "edit") {
      return <EditItem {...state} {...props} />;
    }
  }
}
