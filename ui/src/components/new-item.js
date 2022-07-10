import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { UnControlled as CodeMirror } from 'react-codemirror2';
import 'codemirror/mode/markdown/markdown';
import 'codemirror/addon/display/placeholder';
import { dateToDa } from '../lib/util';
import _ from 'lodash';
import { uuid } from '../lib/util';

export class NewItem extends Component {
  constructor(props) {
    super(props);

    this.state = {
      title: '',
      bodyFront: '',
      bodyBack: '',
      awaiting: false,
      submit: false,
      error: false,
      itemed: false
    };

    this.titleChange = this.titleChange.bind(this);
    this.bodyFrontChange = this.bodyFrontChange.bind(this);
    this.bodyBackChange = this.bodyBackChange.bind(this);
    this.itemSubmit = this.itemSubmit.bind(this);
    this.discardItem = this.discardItem.bind(this);

    this.item = false;
  }

  itemSubmit() {
    const last = this.props.location.state || false;
    let ship = window.ship;
    let stackId = null;

    if (last) {
      ship = (' ' + last.lastParams.ship.slice(1)).slice(1);
      stackId = (' ' + last.lastParams.stack).slice(1);
    } else {
      stackId = this.props.stack;
    }

    const itemTitle = this.state.title;
    const itemId = uuid();

    const awaiting = Object.assign({}, {
      ship: ship,
      stackId: stackId,
      itemId: itemId
    });

    const permissions = {
      read: {
        mod: 'black',
        who: []
      },
      write: {
        mod: 'white',
        who: []
      }
    };
    const front = this.state.bodyFront;
    const back = this.state.bodyBack;

    if (!this.state.error) {
      const newItem = {
        'new-item': {
          'stack-owner': this.props.ship,
          who: ship,
          stak: stackId,
          name: itemId,
          title: itemTitle,
          perm: permissions,
          front: front,
          back: back
        }
      };

      this.props.setSpinner(true);

      this.setState({
        awaiting: awaiting,
        itemed: {
          who: ship,
          stackId: stackId,
          itemId: itemId
        }
      }, () => {
        this.props.api.action('seer', 'seer-action', newItem);
      }
      );
    } else {
      const editItem = {
        'edit-item': {
          who: ship,
          stack: stackId,
          name: itemId,
          title: itemTitle,
          perm: permissions,
          front: front,
          back: back
        }
      };

      this.props.setSpinner(true);

      this.setState({
        awaiting: awaiting
      }, () => {
        this.props.api.action('seer', 'seer-action', editItem);
      });
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.awaiting) {
      const ship = this.state.awaiting.ship;
      const stackId = this.state.awaiting.stackId;
      const itemId = this.state.awaiting.itemId;
      const item = ship === window.ship
        ? this.props.pubs[stackId].items[itemId] || false
        : this.props.subs[ship][stackId].items[itemId] || false;

      if (!_.isEqual(this.item, item)) {
        if (typeof (item) === 'string') {
          this.props.setSpinner(false);
          this.setState({
            awaiting: false,
            error: item
          });
        } else {
          this.props.setSpinner(false);
          const redirect = `/seer/~${ship}/${stackId}/${itemId}`;
          this.props.history.push(redirect);
        }
      }
      if (item) {
        this.item = item;
      }
    }
  }

  discardItem() {
    const last = this.props.location.state || false;
    let ship = window.ship;
    let stackId = null;

    if (last) {
      ship = (' ' + last.lastParams.ship.slice(1)).slice(1);
      stackId = (' ' + last.lastParams.stack).slice(1);
    }

    if (this.state.error && (ship === window.ship)) {
      const del = {
        'delete-item': {
          stack: this.state.itemed.stackId,
          item: this.state.itemed.itemId
        }
      };

      this.props.api.action('seer', 'seer-action', del);
    }

    const redirect = `/seer/~${ship}/${stackId}`;
    this.props.history.push(redirect);
  }

    titleChange(editor, data, value) {
        const submit = !(value === '');
        this.setState({ title: value, submit: submit });
    }
    bodyFrontChange(editor, data, value) {
        const submit = !(value === '');
        this.setState({ bodyFront: value, submit: submit });
    }
    bodyBackChange(editor, data, value) {
        const submit = !(value === '');
        this.setState({ bodyBack: value, submit: submit });
    }

  render() {
    const { props, state } = this;
    const options = {
            mode: 'markdown',
            theme: 'tlon',
            lineNumbers: false,
            lineWrapping: true,
            cursorHeight: 0.85
        };

    let date = dateToDa(new Date());
    date = date.slice(1, -10);
    const submitStyle = (state.submit)
        ? { color: '#2AA779', cursor: 'pointer' }
        : { color: '#B1B2B3', cursor: 'auto' };

    return (
         <div className="f9 h-100 w-100 relative">
                <div className="w-100 tl pv4 flex justify-center">
                    <button
                        className="v-mid bg-transparent w-100 w-80-m w-90-l mw6 tl h1 pl4"
                        disabled={!state.submit}
                        style={submitStyle}
                        onClick={this.itemSubmit}
                    >
                        save &ldquo;{props.stack}&rdquo;
                    </button>
                    <Link to={`/seer/${props.ship}/${props.stack}`} className="blue3 ml2">
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
                        options={{ ...options, ...{ placeholder: 'title' } }}
                        onChange={(e, d, v) => this.titleChange(e, d, v)}
                      />
                    </div>
                    <div className="EditItem">
                        <CodeMirror
                            value=""
                          options={{ ...options, ...{ placeholder: 'front' } }}
                            onChange={(e, d, v) => this.bodyFrontChange(e, d, v)}
                        />
                    </div>
                    <div className="EditItem">
                      <CodeMirror
                        value=""
                          options={{ ...options, ...{ placeholder: 'back' } }}
                            onChange={(e, d, v) => this.bodyBackChange(e, d, v)}
                      />
                    </div>
                </div>
            </div>
        );
    }
}
