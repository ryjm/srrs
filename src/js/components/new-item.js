import React, { Component } from 'react';
import classnames from 'classnames';
import { Link } from 'react-router-dom';
import { UnControlled as CodeMirror } from 'react-codemirror2';
import 'codemirror/mode/markdown/markdown';
import 'codemirror/addon/display/placeholder';
import { dateToDa } from '/lib/util';
import _ from 'lodash';
import { PathControl } from '/components/lib/path-control';
import { withRouter } from 'react-router';
import { stringToSymbol } from '/lib/util';

const PC = withRouter(PathControl);

export class NewItem extends Component {
  constructor(props) {
    super(props);

    this.state = {
      title: "",
      bodyFront: "",
      bodyBack: "",
      awaiting: false,
      submit: false,
      error: false,
      itemed: false,
    };

    this.titleChange = this.titleChange.bind(this);
    this.bodyFrontChange = this.bodyFrontChange.bind(this);
    this.bodyBackChange = this.bodyBackChange.bind(this);
    this.itemSubmit = this.itemSubmit.bind(this);
    this.discardItem = this.discardItem.bind(this);


    this.item = false;
  }

  itemSubmit() {
    let last = _.get(this.props, 'location.state', false);
    let ship = window.ship;
    let stackId = null;

    if (last) {
      ship = (' ' + last.lastParams.ship.slice(1)).slice(1);
      stackId = (' ' + last.lastParams.stack).slice(1);
    } else {
      stackId = this.props.stack
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
    let front = this.state.bodyFront;
    let back = this.state.bodyBack;

    if (!this.state.error) {
      let newItem = {
        "new-item": {
          who: ship,
          stak: stackId,
          name: itemId,
          title: itemTitle,
          perm: permissions,
          front: front,
          back: back
        },
      };

      let raiseItem = {
        "raise-item": {
          who: ship,
          stak: stackId,
          item: itemId,
        },
      };

      this.props.setSpinner(true);

      this.setState({
        awaiting: awaiting,
        itemed: {
          who: ship,
          stackId: stackId,
          itemId: itemId,
        }
      }, () => {
        this.props.api.action("srrs", "srrs-action", newItem).then(() => {
          this.props.api.action("srrs", "srrs-action", raiseItem);
        })
      }
      );

    } else {
      let editItem = {
        "edit-item": {
          who: ship,
          stack: stackId,
          name: itemId,
          title: itemTitle,
          perm: permissions,
          front: front,
          back: back
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
        if (typeof (item) === 'string') {
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

    if (last) {
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

    titleChange(editor, data, value) {
        let submit = !(value === '');
        this.setState({ title: value, submit: submit });
    }
    bodyFrontChange(editor, data, value) {
        let submit = !(value === '');
        this.setState({ bodyFront: value, submit: submit });
    }
    bodyBackChange(editor, data, value) {
        let submit = !(value === '');
        this.setState({ bodyBack: value, submit: submit });
    }

  render() {
    const {props, state} = this
    const options = {
            mode: 'markdown',
            theme: 'tlon',
            lineNumbers: false,
            lineWrapping: true,
            cursorHeight: 0.85
        };

    let date = dateToDa(new Date());
    date = date.slice(1, -10);
    let submitStyle = (state.submit)
        ? { color: '#2AA779', cursor: "pointer" }
        : { color: '#B1B2B3', cursor: "auto" };


    return (
         <div className="f9 h-100 relative">
                <div className="w-100 tl pv4 flex justify-center">
                    <button
                        className="v-mid bg-transparent w-100 w-80-m w-90-l mw6 tl h1 pl4"
                        disabled={!state.submit}
                        style={submitStyle}
                        onClick={this.itemSubmit}>
                        Save "{props.stack}"
                    </button>
                    <Link to={`/~srrs/~${props.ship}/${props.stack}`} className="blue3 ml2">
                        {`<- ${props.stack}`}
                    </Link>
                </div>
                <div className="mw6 center">
                    <div className="pl4">
                        <div className="gray2">{date}</div>
                    </div>
                    <div className="EditItem">
                      <CodeMirror
                        value=""
                        options={{...options, ...{placeholder: "Title"}}}
                        onChange={(e, d, v) => this.titleChange(e, d, v)}                          
                        />
                    </div>
                    <div className="EditItem">
                        <CodeMirror
                            value=""
                          options={{...options, ...{placeholder: "Front"}}}                            
                            onChange={(e, d, v) => this.bodyFrontChange(e, d, v)}
                        />
                    </div>
                    <div className="EditItem">
                      <CodeMirror
                        value=""                        
                          options={{...options, ...{placeholder: "Back"}}}
                            onChange={(e, d, v) => this.bodyBackChange(e, d, v)}
                            
                        />
                    </div>
                </div>
            </div>
        );
    }
}
