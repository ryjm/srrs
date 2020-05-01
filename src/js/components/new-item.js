import React, { Component } from 'react';
import classnames from 'classnames';
import { Link } from 'react-router-dom';
import _ from 'lodash';
import { PathControl } from '/components/lib/path-control';
import { withRouter } from 'react-router';
import { stringToSymbol } from '/lib/util';

const PC = withRouter(PathControl);

class SideTab extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (this.props.enabled){
      return (
        <div className="w1 z-2 body-regular"
          style={{
            flexGrow:1,
        }}>
          <p className="pointer" onClick={this.props.itemSubmit}>
            -> Item
          </p>
          <p className="pointer" onClick={this.props.discardItem}>
            Discard note
          </p>
        </div>
      );
    }
    return (
      <div style={{flexGrow: 1, height:48}}></div>
    );
  }
}

class Error extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (this.props.error) {
      let lines = this.props.error.split("\n").map((line, i) => {
        return (<p key={i}>{line}</p>);
      });

      return (
        <div className="w-100 flex-col">
          <p className="w-100 bg-red label-regular pt2 pb2 pl3">
            This item contains an error
          </p>
          <div className="label-regular-mono bg-v-light-gray pb3 pt3">
            <div className="center mw-688 w-100">
              {lines}
            </div>
          </div>
        </div>
      );
    } else {
      return null;
    }
  }
}

export class NewItem extends Component {
  constructor(props){
    super(props);

    this.state = {
      title: "",
      body: "",
      awaiting: false,
      error: false,
      itemed: false,
    };

    this.titleChange = this.titleChange.bind(this);
    this.bodyChange = this.bodyChange.bind(this);
    this.itemSubmit = this.itemSubmit.bind(this);
    this.discardItem = this.discardItem.bind(this);

    this.windowHeight = window.innerHeight - 48 - 76;

    this.bodyHeight = 54;
    this.titleHeight = 102;


    this.item = false;
  }

  itemSubmit() {
    let last = _.get(this.props, 'location.state', false);
    let ship = window.ship;
    let stackId = null;

    if (last){
      ship = (' ' + last.lastParams.ship.slice(1)).slice(1);
      stackId = (' ' + last.lastParams.stack).slice(1);
    }

    let itemTitle = this.state.title;
    let itemId = stringToSymbol(itemTitle);

    let awaiting = Object.assign({}, {
      ship: ship,
      stackId: stackId,
      itemId: itemId,
    });

    let permissions = {
      read: {
        mod: 'black',
        who: [],
      },
      write: {
        mod: 'white',
        who: [],
      }
    };
    let content = this.state.body;

    if (!this.state.error) {
      let newItem = {
        "new-item" : {
          who: ship,
          stak: stackId,
          name: itemId,
          title: itemTitle,
          perm: permissions,
          content: content,
        },
      };

      this.props.setSpinner(true);

      this.setState({
        awaiting: awaiting,
        itemed: {
          ship: ship,
          stackId: stackId,
          itemId: itemId,
        }
      }, () => {
        this.props.api.action("srrs", "srrs-action", newItem);
      });

    } else {
      let editItem = {
        "edit-item" : {
          who: ship,
          stack: stackId,
          name: itemId,
          title: itemTitle,
          perm: permissions,
          content: content,
        },
      };

      this.props.setSpinner(true);

      this.setState({
        awaiting: awaiting,
      }, () => {
        this.props.api.action("srrs", "srrs-action", editItem);
      });
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.awaiting) {
      let ship = this.state.awaiting.ship;
      let stackId = this.state.awaiting.stackId;
      let itemId = this.state.awaiting.itemId;
      let item;

      if (ship == window.ship) {
        item =
          _.get(this.props,
            `pubs["${stackId}"].items["${itemId}"]`, false) || false;
      } else {
        item =
          _.get(this.props,
            `subs["${ship}"]["${stackId}"].items["${itemId}"]`, false) || false;

      }
      if (!_.isEqual(this.item, item)) {
        if (typeof(item) === 'string') {
          this.props.setSpinner(false);
          this.setState({
            awaiting: false,
            error: item
          });
        } else {
          this.props.setSpinner(false);
          let redirect = `/~srrs/~${ship}/${stackId}/${itemId}`;
          this.props.history.push(redirect);
        }
      }
      if (item) {
        this.item = item;
      }
    }
  }

  discardItem() {
    let last = _.get(this.props, 'location.state', false);
    let ship = window.ship;
    let stackId = null;

    if (last){
      ship = (' ' + last.lastParams.ship.slice(1)).slice(1);
      stackId = (' ' + last.lastParams.stack).slice(1);
    }

    if (this.state.error && (ship === window.ship)) {
      let del = {
        "delete-item": {
          stack: this.state.itemed.stackId,
          item: this.state.itemed.itemId,
        }
      };

      this.props.api.action("srrs", "srrs-action", del);
    }

    let redirect = `/~srrs/~${ship}/${stackId}`;
    this.props.history.push(redirect);
  }

  titleChange(evt){
    this.titleInput.style.height = 'auto';
    this.titleInput.style.height = this.titleInput.scrollHeight+2+'px';
    this.titleHeight = this.titleInput.style.height;

    this.setState({title: evt.target.value});
  }

  bodyChange(evt){
    this.bodyInput.style.height = 'auto';
    this.bodyInput.style.height = this.bodyInput.scrollHeight+2+'px';
    this.bodyHeight = this.bodyInput.style.height;

    this.setState({body: evt.target.value});
  }

  render() {
    let enabledTab = ((this.state.title !== "") && (this.state.body !== ""));

    let mt = (this.windowHeight/2) - 110;
    let mb = (this.windowHeight/2) - 90;

    return (
      <div className="relative w-100" style={{top:124}}>
        <PC pathData={false} {...this.props}/>
        <Error error={this.state.error}/>
        <div>
          <div className="w-100" style={{height: mt}}></div>

          <div className="flex w-100 z-2" style={{position: 'sticky', top: 132}}>
            <div className="w1 z-0" style={{flexGrow:1}}></div>
            <div className="mw-688 w-100 z-0" style={{pointerEvents:'none'}}></div>
            <SideTab
              enabled={enabledTab}
              itemSubmit={this.itemSubmit}
              discardItem={this.discardItem}
            />
          </div>

          <div className="flex relative" style={{top:-74}}>
            <div className="w1 z-0" style={{flexGrow:1}}></div>
            <div className="flex-col w-100 mw-688 w-100 z-2">
              <textarea autoFocus
                className="header-2 w-100 b--none overflow-y-hidden"
                ref={(el) => {this.titleInput = el}}
                style={{resize:"none", marginBottom:8, height: this.titleHeight}}
                placeholder="Add a Title"
                onChange={this.titleChange.bind(this)}>
              </textarea>
              <textarea
                className="body-regular-400 w-100 z-2 b--none overflow-y-hidden"
                ref={(el) => {this.bodyInput = el}}
                style={{resize:"none", height: this.bodyHeight}}
                placeholder="And type away."
                onChange={this.bodyChange.bind(this)}>
              </textarea>
            </div>
            <div className="w1 z-0" style={{flexGrow:1}}></div>
          </div>

          <div className="w-100" style={{height: mb}}></div>
        </div>
      </div>
    );
  }
}
