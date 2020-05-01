import React, { Component } from 'react';
import classnames from 'classnames';
import _ from 'lodash';
import { PathControl } from '/components/lib/path-control';
import { StackData } from '/components/lib/stack-data';
import { StackNotes } from '/components/lib/stack-notes';
import { StackSubs } from '/components/lib/stack-subs';
import { StackSettings } from '/components/lib/stack-settings';
import { withRouter } from 'react-router';
import { NotFound } from '/components/not-found';
import { Link } from 'react-router-dom';

const PC = withRouter(PathControl);
const NF = withRouter(NotFound);
const BN = withRouter(StackNotes);
const BS = withRouter(StackSettings)


export class Stack extends Component {
  constructor(props){
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
      notFound: false,
    };

    this.subscribe = this.subscribe.bind(this);
    this.unsubscribe = this.unsubscribe.bind(this);
    this.viewSubs = this.viewSubs.bind(this);
    this.viewSettings = this.viewSettings.bind(this);
    this.viewNotes = this.viewNotes.bind(this);

    this.stack = null;
  }

  handleEvent(diff) {
    
    if (diff.data.total) {
      let stack = diff.data.total.data;
      this.stack = stack;
      this.setState({
        itemProps: this.buildItems(stack),
        stack: stack,
        stackTitle: stack.info.title,
        stackHost: stack.info.owner,
        awaiting: false,
        pathData: [
          { text: "Home", url: "/~srrs/review" },
          { text: stack.info.title,
            url: `/~srrs/${stack.info.owner}/${stack.info.filename}` }
        ],
      });

      this.props.setSpinner(false);
    } else if (diff.data.remove) {
      if (diff.data.remove.item) {
       // XX TODO
      } else {
        this.props.history.push("/~srrs/review");
      }
    }
  }

  handleError(err) {
    this.props.setSpinner(false);
    this.setState({notFound: true});
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.notFound) return;

    let ship = this.props.ship;
    let stackId = this.props.stackId;

    let stack = (ship === window.ship)
      ?  _.get(this.props, `pubs["${stackId}"]`, false)
      :  _.get(this.props, `subs["${ship}"]["${stackId}"]`, false);


    if (!(stack) && (ship === window.ship)) {
      this.setState({notFound: true});
      return;
    } else if (this.stack && !stack) {
      this.props.history.push("/~srrs/review");
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
    let ship = this.props.ship;
    let stackId = this.props.stackId;
    let stack = (ship == window.ship)
      ?  _.get(this.props, `pubs["${stackId}"]`, false)
      :  _.get(this.props, `subs["${ship}"]["${stackId}"]`, false);

    if (!(stack) && (ship === window.ship)) {
      this.setState({notFound: true});
      return;
    };

    let temporary = (!(stack) && (ship != window.ship));

    if (temporary) {
      this.setState({
        awaiting: {
          ship: ship,
          stackId: stackId,
        },
        temporary: true,
      });

      this.props.setSpinner(true);

      this.props.api.bind(`/stack/${stackId}`, "PUT", ship, "srrs",
        this.handleEvent.bind(this),
        this.handleError.bind(this));
    } else {
      this.stack = stack;
    }
  }

  buildItems(stack){
    if (!stack) {
      return [];
    }
    
    let pinProps = stack.order.pin.map((itemId) => {
      let item = stack.items[itemId];
      return this.buildItemPreviewProps(item, stack, true);
    });

    let unpinProps = stack.order.unpin.map((itemId) => {
      let item = stack.items[itemId];
      return this.buildItemPreviewProps(item, stack, false);
    });

    return pinProps.concat(unpinProps);
  }

  buildItemPreviewProps(item, stack, pinned){

    return {
      itemTitle: item.content.title,
      itemName:  item.content["note-id"],
      itemBody: item.content.file,
      itemSnippet: item.content.snippet,
      stackTitle: stack.info.title,
      stackName:  stack.info.filename,
      author: item.content.author,
      stackOwner: stack.info.owner,
      date: item.content["date-created"],
      pinned: pinned,
    }
  }

  buildData(){
    let stack = (this.props.ship == window.ship)
      ?  _.get(this.props, `pubs["${this.props.stackId}"]`, false)
      :  _.get(this.props, `subs["${this.props.ship}"]["${this.props.stackId}"]`, false);

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
          { text: "Home", url: "/~srrs/review" },
          { text: stack.info.title,
            url: `/~srrs/${stack.info.owner}/${stack.info.filename}` }
        ],
      };
    }
  }

  subscribe() {
    let sub = {
      subscribe: {
        who: this.props.ship,
        stack: this.props.stackId,
      }
    }
    this.props.setSpinner(true);
    this.setState({awaitingSubscribe: true}, () => {
      this.props.api.action("srrs", "srrs-action", sub);
    });
  }

  unsubscribe() {
    let unsub = {
      unsubscribe: {
        who: this.props.ship,
        stack: this.props.stackId,
      }
    }
    this.props.api.action("srrs", "srrs-action", unsub);
    this.props.history.push("/~srrs/review");
  }

  viewSubs() {
    this.setState({view: 'subs'});
  }

  viewSettings() {
    this.setState({view: 'settings'});
  }

  viewNotes() {
    this.setState({view: 'notes'});
  }

  render() {

    if (this.state.notFound) {
      return (
        <NF/>
      );
    } else if (this.state.awaiting) {
      return null;
    } else {
      let data = this.buildData();

      let contributors = `~${this.props.ship}`;
      let create = (this.props.ship === window.ship);

      let subNum = _.get(data.stack, 'subscribers.length', 0);

      let foreign = _.get(this.props,
        `subs["${this.props.ship}"]["${this.props.stackId}"]`, false);

      let actionType = false;
      if (this.state.temporary) {
        actionType = 'subscribe';
      } else if ((this.props.ship !== window.ship) && foreign) {
        actionType = 'unsubscribe';
      }

      let viewSubs = (this.props.ship === window.ship)
        ? this.viewSubs
        : null;

      let viewSettings = (this.props.ship === window.ship)
        ? this.viewSettings
        : null;

      if (this.state.view === 'notes') {
        return (
          <div>
            <PC pathData={data.pathData} create={create}/>
            <div className="absolute w-100"
              style={{top:124, paddingLeft: 16, paddingRight: 16, paddingTop: 32}}>
              <div className="flex-col">
                <h2 style={{wordBreak: "break-word"}}>
                  {data.stackTitle}
                </h2>
                <div className="flex" style={{marginTop: 22}}>
                  <StackData
                    host={this.props.ship}
                    viewSubs={viewSubs}
                    subNum={subNum}
                    viewSettings={viewSettings}
                    subscribeAction={actionType}
                    subscribe={this.subscribe}
                    unsubscribe={this.unsubscribe}
                  />
                </div>
                <BN ship={this.props.ship} items={data.itemProps} />
              </div>
            </div>
          </div>
        );
      } else if (this.state.view === 'subs') {
        let subscribers = _.get(data, 'stack.subscribers', []);
        return (
          <div>
            <PC pathData={data.pathData} create={create}/>
            <div className="absolute w-100"
              style={{top:124, paddingLeft: 16, paddingRight: 16, paddingTop: 32}}>
              <div className="flex-col">
                <h2 style={{wordBreak: "break-word"}}>
                  {data.stackTitle}
                </h2>
                <div className="flex" style={{marginTop: 22}}>
                  <StackData
                    host={this.props.ship}
                    viewSubs={viewSubs}
                    subNum={subNum}
                    viewSettings={viewSettings}
                    subscribeAction={actionType}
                    subscribe={this.subscribe}
                    unsubscribe={this.unsubscribe}
                  />
                </div>
                <StackSubs back={this.viewNotes}
                  subs={subscribers}
                  stackId={this.props.stackId}
                  title={data.stackTitle}
                  api={this.props.api}/>
              </div>
            </div>
          </div>
        );
      } else if (this.state.view === 'settings') {
        return (
          <div>
            <PC pathData={data.pathData} create={create}/>
            <div className="absolute w-100"
              style={{top:124, paddingLeft: 16, paddingRight: 16, paddingTop: 32}}>
              <div className="flex-col">
                <h2 style={{wordBreak: "break-word"}}>
                  {data.stackTitle}
                </h2>
                <div className="flex" style={{marginTop: 22}}>
                  <StackData
                    host={this.props.ship}
                    viewSubs={viewSubs}
                    subNum={subNum}
                    viewSettings={viewSettings}
                    subscribeAction={actionType}
                    subscribe={this.subscribe}
                    unsubscribe={this.unsubscribe}
                  />
                </div>
                <BS back={this.viewNotes}
                  stackId={this.props.stackId}
                  title={data.stackTitle}
                  api={this.props.api}/>
              </div>
            </div>
          </div>
        );
      }
    }
  }
}

