import React, { Component } from 'react';
import { StackNotes } from '~/lib/stack-notes';
import { withRouter } from 'react-router';
import { NotFound } from '~/components/not-found';
import { Link } from 'react-router-dom';

const NF = withRouter(NotFound);
const BN = withRouter(StackNotes);

export class Stack extends Component {
  constructor(props) {
    super(props);

    this.state = {
      view: 'notes',
      awaiting: false,
      itemProps: [],
      stackTitle: '',
      stackHost: '',
      pathData: [],
      temporary: false,
      awaitingSubscribe: false,
      awaitingUnsubscribe: false,
      notFound: false
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
          { text: 'Home', url: '/~srrs/review' },
          {
            text: stack.info.title,
            url: `/~srrs/${stack.info.owner}/${stack.info.filename}`
          }
        ]
      });

      this.props.setSpinner(false);
    } else if (diff.data.remove) {
      if (diff.data.remove.item) {
        // XX TODO
      } else {
        this.props.history.push('/~srrs/review');
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
    const stack = (ship === window.ship)
      ? this.props.pubs[stackId] || false
      : this.props.subs[ship][stackId] || false;

    if (!(stack) && (ship === window.ship)) {
      this.setState({ notFound: true });
      return;
    } else if (this.stack && !stack) {
      this.props.history.push('/~srrs/review');
      return;
    }

    this.stack = stack;

    if (this.state.awaitingSubscribe && stack) {
      this.setState({
        temporary: false,
        awaitingSubscribe: false
      });

      this.props.setSpinner(false);
    }
  }

  componentWillMount() {
    const ship = this.props.ship;
    const stackId = this.props.stackId;
    const stack = (ship === window.ship)
      ? this.props.pubs[stackId] || false
      : this.props.subs[ship][stackId] || false;

    if (!(stack) && (ship === window.ship)) {
      this.setState({ notFound: true });
      return;
    };

    const temporary = (!(stack) && (ship != window.ship));

    if (temporary) {
      this.setState({
        awaiting: {
          ship: ship,
          stackId: stackId
        },
        temporary: true
      });

      this.props.setSpinner(true);

      this.props.api.bind(`/stack/${stackId}`, 'PUT', ship, 'srrs',
        this.handleEvent.bind(this),
        this.handleError.bind(this));
    } else {
      this.stack = stack;
    }
  }

  deleteStack() {
    const del = {
      'delete-stack': {
        who: `~${this.props.ship}`,
        stak: this.props.stackId
        }
    };
    this.props.setSpinner(true);
    this.setState({
      awaitingDelete: {
        ship: this.props.ship,
        stackId: this.props.stackId
      }
    }, () => {
      this.props.api.action('srrs', 'srrs-action', del).then(() => {
       const redirect = '/~srrs/review';
        this.props.history.push(redirect);
      });
    });
  }

  reviewStack() {
    const action = {
      'review-stack': {
        who:  `~${this.props.ship}`,
        stak: this.props.stackId
      }
    };
    this.props.api.action('srrs', 'srrs-action', action);
    this.props.history.push(`/~srrs/~${this.props.ship}/${this.props.stackId}/review`);
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
      itemTitle: item.content.title,
      itemName: item.name,
      itemBody: item.content.front,
      itemSnippet: item.content.snippet,
      stackTitle: stack.info.title,
      stackName: stack.info.filename,
      author: item.content.author,
      stackOwner: stack.info.owner,
      date: item.content['date-created'],
      pinned: pinned
    };
  }

  buildData() {
    const ship = this.props.ship;
    const stackId = this.props.stackId;
    const stack = (ship === window.ship)
      ? this.props.pubs[stackId] || false
      : this.props.subs[ship][stackId] || false;

    if (this.state.temporary) {
      return {
        stack: this.state.stack,
        itemProps: this.state.itemProps,
        stackTitle: this.state.stackTitle,
        stackHost: this.state.stackHost,
        pathData: this.state.pathData
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
          { text: 'Home', url: '/~srrs/review' },
          {
            text: stack.info.title,
            url: `/~srrs/${stack.info.owner}/${stack.info.filename}`
          }
        ]
      };
    }
  }

  subscribe() {
    const sub = {
      subscribe: {
        who: this.props.ship,
        stack: this.props.stackId
      }
    };
    this.props.setSpinner(true);
    this.setState({ awaitingSubscribe: true }, () => {
      this.props.api.action('srrs', 'srrs-action', sub);
    });
  }

  unsubscribe() {
    const unsub = {
      unsubscribe: {
        who: this.props.ship,
        stack: this.props.stackId
      }
    };
    this.props.api.action('srrs', 'srrs-action', unsub);
    this.props.history.push('/~srrs/review');
  }

  viewSubs() {
    this.setState({ view: 'subs' });
  }

  viewSettings() {
    this.setState({ view: 'settings' });
  }

  viewNotes() {
    this.setState({ view: 'notes' });
  }

  render() {
    const { props } = this;
    const localStack = props.ship === window.ship;

    if (this.state.notFound) {
      return (
        <NF />
      );
    } else if (this.state.awaiting) {
      return null;
    } else {
      const data = this.buildData();
      let inner = null;
      switch (props.view) {
        case 'notes':
          inner = <BN ship={this.props.ship} items={data.itemProps} />;
      }

      return (
      <div
        className="overflow-y-scroll"
        style={{ paddingLeft: 16, paddingRight: 16 }}
        onScroll={this.onScroll}
        ref={(el) => {
          this.scrollElement = el;
        }}
      >
        <div className="w-100 dn-m dn-l dn-xl inter pt4 pb6 f9">
          <Link to="/~srrs/review">{'<- Review'}</Link>
        </div>
        <div className="mw9 f9 h-100"
          style={{ paddingLeft: 16, paddingRight: 16 }}
        >
          <div className="h-100 pt0 pt8-m pt8-l pt8-xl no-scrollbar">
            <div
              className="flex justify-between"
              style={{ marginBottom: 32 }}
            >
              <div
               className="flex-col"
              >
                <div className="mb1">{data.stackTitle}</div>
                <span>
                  <span className="gray3 mr1">by</span>
                  <span className={'mono'}
                    title={data.stackHost}
                  >
                    {data.stackHost}
                  </span>
                </span>
              </div>
              <div className="flex">
              {localStack && <Link to={`/~srrs/~${this.props.ship}/${data.stack.info.filename}/new-item`} className="StackButton bg-light-green green2">
                  New Item
               </Link>}
            {localStack && <p className="StackButton bg-light-green green2 ml2" onClick={this.reviewStack}>Review all items</p>}
            <p className="StackButton bg-gray3 black ml2"
            onClick={this.deleteStack}
            >
                  Delete Stack
            </p>
              </div>
            </div>

            <div className="flex" style={{ marginBottom: 24 }}>
            <Link to={`/~srrs/${data.stack.info.owner}/${data.stack.info.filename}/review`} className="bb b--gray4 b--gray2-d gray2 pv4 ph2">
                Review
              </Link>

              <div className="bb b--gray4 b--gray2-d gray2 pv4 ph2"
                style={{ flexGrow: 1 }}
              ></div>
            </div>

            <div style={{ height: 'calc(100% - 188px)' }} className="f9 lh-solid">
              {inner}
            </div>
          </div>
        </div>
      </div>
      );
    }
  }
}

