import { ArrowCircleLeft } from '@mui/icons-material';
import { Button, IconButton, Stack } from '@mui/joy';
import moment from 'moment';
import React, { Component } from 'react';
import { withRouter } from 'react-router';
import { Link } from 'react-router-dom';
import { justifyContent } from 'styled-system';

import momentConfig from '../config/moment';
import { ItemBody } from '../lib/item-body';
import { EditItem } from './edit-item';
import { NotFound } from './not-found';
import { Recall } from './recall';

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
    const localStack = props.ship === window.ship;
    if (ship !== window.ship) {
      const stack = this.props.subs[ship][stackId];

      if (stack) {
        let item = stack.items[itemId];
        let next =
          locstate && locstate.next ? locstate.next : this.getNextItem(0);
        let nextStack =
          next && next[1].stack
            ? this.props.pubs[next[1].stack]
            : localStack
            ? null
            : this.props.subs[stack.info.owner.slice(1)][stack.info.title];
        let nextReview = nextStack
          ? this.getNextReview(
              Object.entries(nextStack["review-items"]).indexOf(next[1].item)
            )
          : null;
        const learn = item.learn;
        const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
        const itemUrl = `${stackUrl}/${item.item}`;
        next = item.item === next[1].item ? nextReview : next;
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
      this.state = { ...this.state, stack: stack };
      const item = stack.items[itemId];
      const learn = item.learn;

      if (!stack || !item) {
        this.state = { ...this.state, ...{ notFound: true } };
        return;
      } else {
        const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
        const itemUrl = `${stackUrl}/${item.name}`;
        let next =
          locstate && locstate.next
            ? locstate.next
            : this.getNextItem(0, stack);
        let nextStack = next && next[1].name ? stack : null;
        next = item.name === next[1].name ? this.getNextItem(1, stack) : next;
        this.state = {
          ...this.state,
          title: item.content.title,
          bodyFront: item.content.front,
          bodyBack: item.content.back,
          next: next,
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
  getNextItem(idx: number, stack?): any {
    if (typeof stack === "undefined") {
      stack = this.state.stack;
    }
    const { item, ship } = this.state;

    const stak = stack ? stack : this.props.pubs[this.props.stackId];
    idx = idx ? idx : 0;
    if (this.state.mode !== "review") {
      const items = Array.from(Object.entries(stak.items));
      const nextItem = items[idx] ? items[idx] : items[0];
      const nextId = nextItem[1].name;
      const stackUrl = `/seer/~${ship}/${stak.info.filename}`;
      const nextUrl = `${stackUrl}/${nextId}`;
      return [nextUrl, nextItem[1]];
    } else if (this.state.mode === "review") {
      const nextReview = this.getNextReview(idx);
      return nextReview;
    }
  }

  getNextReview(idx: number, stack?): any {
    if (typeof stack === "undefined") {
      stack = this.state.stack;
    }
    if (idx === -1) {
      return ["/seer/review", null];
    }
    const { ship } = this.state;

    const locstate = this.props.location.state;

    const stackReviews = Array.from(Object.entries(stack["review-items"]));
    if (stackReviews.length === 0) {
      return ["/seer/review", null];
    }
    if (stackReviews.length === 1) {
      return ["/seer/review", null];
    }
    if (idx >= stackReviews.length) {
      return this.getNextItem(0);
    }
    const item = stackReviews[idx] ? stackReviews[idx] : stackReviews[0];

    const stackUrl = `/seer/${stack.info.owner}/${stack.info.filename}`;
    if (!item) return ["/seer/review", null];
    const itemUrl = `${stackUrl}/${item[1].name}`;

    if (this.state.reviews.length === 1) return [itemUrl, item[1]];
    if (item && item[1].name !== this.state.item.name) {
      return [itemUrl, item[1]];
    }
    return this.getNextReview(idx + 1);
  }
  randomReview() {
    if (this.state.reviews.length === 0) {
      return ["/seer/review", null];
    }
    const item =
      this.state.reviews[Math.floor(Math.random() * this.state.reviews.length)];
    const stackUrl = `/seer/${item.who}/${item.stack}`;
    const itemUrl = `${stackUrl}/${item.item}`;
    return [itemUrl, item];
  }
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
        mode: "grade",
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
      const itemUrl = `${stackUrl}/${item.item}`;

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

      let redirect = "/seer/review";
      if (this.state.mode === "review") {
        redirect = this.getNextReview(
          this.state.reviews.map((rev) => rev.item).indexOf(itemId)
        )[0];
      } else redirect = this.state.next[0];
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
          showBack: false,
        },
        () => {
          this.props.history.push(redirect);
        }
      );
    }
    if (!this.state.temporary) {
      if (
        this.props.location.state &&
        this.props.location.state.mode &&
        this.props.location.state.mode !== this.state.mode
      ) {
        this.setState({ mode: this.props.location.state.mode });
        this.props.location.state.mode = null;
      }

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
              ? locstate.next
              : this.getNextItem(
                  Object.entries(stack["review-items"]).indexOf(itemId)
                ),
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
        this.props.api.action("seer", "seer-action", del);
        const redirect = `/seer/~${this.props.ship}/${this.props.stackId}`;
        this.props.history.push(redirect);
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

      const stackLength = Object.entries(
        this.props.pubs[this.props.stackId].items
      ).length;
      let idx = locstate ? locstate.idx : 0;
      if (idx >= stackLength || Number.isNaN(idx)) {
        idx = 0;
      }

      const next =
        locstate && locstate.next ? locstate.next : this.getNextItem(idx);

      const reviews = this.state.reviews;
      const localStack = props.ship === window.ship;

      return (
        <Stack
          direction="column"
          sx={{
            pl: "16",
            pt: "10",
            minWidth: "300px",
          }}
        >
          <Stack spacing={2} direction="row" sx={{ justifyContent: "left" }}>
            <Link to={`/seer/${host}/${stackTitle}`}>
              <IconButton variant="soft">
                <ArrowCircleLeft /> {stackTitle}
              </IconButton>
            </Link>
            <Link to={`/seer/${host}/${stackTitle}/new-item`}>
              <Button>new item</Button>
            </Link>


              <Button
                onClick={() =>
                  this.state.mode === "review"
                    ? this.setState({ mode: "view" })
                    : this.setState({ mode: "review" })
                }
              >
                toggle {this.state.mode}
              </Button>

            <Link
              to={{
                pathname: next[0],
                state: {
                  next: this.getNextItem(idx),
                  idx: idx + 1,
                  mode: this.state.mode,
                  prevPath: location.pathname,
                },
              }}
            >
              <Button>next</Button>
            </Link>
          </Stack>
          <Stack
            direction="row-reverse"
            sx={{
              alignItems: "stretch",
              pt: 2,
              justifyContent: "space-between",
            }}
          >
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
          </Stack>
          {/*           <Chip variant="outlined">
              <Typography
                textColor="secondary.500"
                fontWeight={700}
                sx={{
                  fontSize: "10px",
                  textTransform: "uppercase",
                  letterSpacing: ".1rem",
                }}
              >
                {title}
              </Typography>
              <Divider />
              {!localStack && (
                <Box sx={{ py: 1 }}>
                  <Chip
                    endDecorator={<Houseboat />}
                    variant="outlined"
                    size="sm"
                  >
                    {host}
                  </Chip>
                </Box>
              )}
            </Chip> */}
        </Stack>
      );
    } else if (this.state.mode == "edit") {
      return <EditItem {...state} {...props} />;
    }
  }
}
