import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { Chance } from 'chance';
//import { UnControlled as CodeMirror } from 'react-codemirror2';
import CodeMirror from '@uiw/react-codemirror'
import { keymap } from '@codemirror/view';
import { defaultKeymap } from '@codemirror/commands';
import { basicSetup } from 'codemirror';
import { emacs } from '@replit/codemirror-emacs';
import { markdown, markdownLanguage} from '@codemirror/lang-markdown';
import { dateToDa } from '../lib/util';
import _, { random, stubString } from 'lodash';
import { uuid } from '../lib/util';
import { Grid, IconButton, Stack, Button } from '@mui/joy';
import { ArrowCircleLeft } from '@mui/icons-material';


export class NewItem extends Component {
  constructor(props) {
    super(props);
    const chance = new Chance();
    this.state = {
      title: chance.word({ length: 4 }),
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
    this.saveItem = this.saveItem.bind(this);
    this.discardItem = this.discardItem.bind(this);

    this.item = false;
  }

  saveItem() {
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

  titleChange(value) {
    const submit = !(value === '');
    this.setState({ title: value, submit: submit });
  }
  bodyFrontChange(value) {
    const submit = !(value === '');
    this.setState({ bodyFront: value, submit: submit });
  }
  bodyBackChange(value) {
    const submit = !(value === '');
    this.setState({ value: value, bodyBack: value, submit: submit });
  }

  render() {
    const { props, state } = this;

    const options = {
      lineNumbers: false,
      lineWrapping: true,
      readOnly: false,
      cursorHeight: 0.85,

    };

    let date = dateToDa(new Date());
    date = date.slice(1, -10);
    const submitStyle = (state.submit)
      ? { color: '#2AA779', cursor: 'pointer' }
      : { color: '#B1B2B3', cursor: 'auto' };

    
      return (
        <Grid
          sx={{ marginLeft: 2, width: "80%" }}
          display="flex"
          alignContent="flex-start"
          justifyContent="space-evenly"
          container
          spacing={2}
        >
          <Stack
            sx={{ p: 2 }}
            alignItems="flex-start"
            justifyItems="space-between"
            width="50%"
          >
            <CodeMirror
              width="100%"
              basicSetup={{
                lineNumbers: false,
              }}
              placeholder="Title"
              className="EditItem"
              extensions={[emacs(), markdown({ base: markdownLanguage })]}
              value={props.title}
              options={{ ...options }}
              onChange={(editor, value) => {
                this.titleChange(editor);
              }}
            />
            <CodeMirror
              width="100%"
              
              placeholder={"Front"}
              basicSetup={{
                  lineNumbers: false,
              }}
              extensions={[
                emacs(),
                markdown({ base: markdownLanguage }),
              ]}
              value={state.bodyFront}
              options={{ ...options }}
              onChange={(e, v) => {
                this.bodyFrontChange(e);
              }}
            />
            <CodeMirror
              width="100%"
              
              placeholder={"Back"}
              basicSetup={{
                  lineNumbers: false,
              }}
              extensions={[
                emacs(),
                markdown({ base: markdownLanguage }),
              ]}
              value={state.bodyBack}
              options={{ ...options }}
              onChange={(e, v) => {
                this.bodyBackChange(e);
              }}
            />
          </Stack>
  
          <Stack
            sx={{ alignItems: "flex-start", p: 2, float: "right" }}
            spacing={2}
          >
            <Button
              disabled={!state.submit}
              onClick={this.saveItem}
              variant="soft"
            >
              Save {props.title}
            </Button>
          
          </Stack>
        </Grid>
      );
    }
  }
  