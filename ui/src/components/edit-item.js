import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { dateToDa } from '../lib/util';
import CodeMirror from '@uiw/react-codemirror'

import { basicSetup } from 'codemirror';
import { emacs } from '@replit/codemirror-emacs';
import { markdown, markdownLanguage} from '@codemirror/lang-markdown';


export class EditItem extends Component {
    constructor(props) {
        super(props);
        this.state = {
            bodyFront: '',
            bodyBack: '',
            title: '',
            submit: false,
            awaiting: false
        };
        this.saveItem = this.saveItem.bind(this);
        this.titleChange = this.titleChange.bind(this);
        this.bodyFrontChange = this.bodyFrontChange.bind(this);
        this.bodyBackChange = this.bodyBackChange.bind(this);
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
        this.setState({ bodyBack: value, submit: submit });
    }

    saveItem() {
        const { props, state } = this;

        this.props.setSpinner(true);
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

        const data = {
            'edit-item': {
                who: props.ship,
                stak: props.stackId,
                name: props.itemId,
                title: state.title,
                perm: permissions,
                front: state.bodyFront,
                back: state.bodyBack

            }
        };

        this.setState({
            awaitingEdit: {
                ship: this.state.ship,
                stackId: this.props.stackId,
                itemId: this.props.itemId
            }
        }, () => {
            this.props.api.action('seer', 'seer-action', data)
            this.setState({ awaiting: false, mode: 'view' });
            const redirect = `/seer/~${props.ship}/${props.stackId}`;
            props.history.push(redirect);
        });
    }
    componentDidMount() {
        const { props } = this;
        const stack = props.pubs[props.stackId];
        const content = stack.items[props.itemId].content;
        const title = content.title;
        const front = content.front;
        const back = content.back;
        const bodyFront = front.slice(front.indexOf(';>') + 3);
        const bodyBack = back.slice(back.indexOf(';>') + 3);
        this.setState({ bodyFront: bodyFront, bodyBack: bodyBack, stack: stack, title: title });
    }

    render() {
        const { props, state } = this;
        const options = {
            
            lineNumbers: false,
            lineWrapping: true,
            cursorHeight: 0.85
        };
        
        /* let stackLinkText = `<- Back to ${this.state.stack.info.title}`; */
        let date = dateToDa(new Date(props.item.content['date-created']));
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
                        onClick={this.saveItem}
                    >
                        save &ldquo;{props.title}&rdquo;
                    </button>
                    <Link to={`/seer/${props.stack.info.owner}/${props.stack.info.filename}`} className="blue3 ml2">
                        {`<- ${props.stack.info.filename}`}
                    </Link>
                </div>
                <div className="mw6 center">
                    <div className="pl4">
                        <div className="gray2">{date}</div>
                    </div>
                    <div>
            <CodeMirror
              height='20%'
              width='50%'
              basicSetup={{
                lineNumbers: false
              }}
              className='EditItem'
              extensions={[emacs(), markdown({ base: markdownLanguage })]}
              value={props.title}
              options={{ ...options }}
              onChange={(editor, value) => {
                this.titleChange(editor)
              }}
            />
          </div>
          <div>
            <CodeMirror
              height='20%'
              extensions={[emacs(), basicSetup, markdown({ base: markdownLanguage })]}
              value={state.bodyFront}
              options={{ ...options }}
              onChange={(e, v) => { this.bodyFrontChange(e) }}
            />
          </div>
          <div>
            <CodeMirror
              height='20%'
              extensions={[emacs(), basicSetup, markdown({ base: markdownLanguage })]}
              value={state.bodyBack}
              options={{ ...options }}
              onChange={(e, v) => { this.bodyBackChange(e) }}
            />
          </div>
        </div>
      </div>
        );
    }
}
