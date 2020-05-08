import { Controlled as CodeMirror } from 'react-codemirror2';
import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import classnames from 'classnames';
import cx from 'classnames-es';
import moment from 'moment';
import { Spinner } from '/components/lib/icons/icon-spinner';
import { dateToDa } from '/lib/util';
import _ from 'lodash';
import 'codemirror/mode/markdown/markdown';

export class EditItem extends Component {
    constructor(props) {
        super(props);
        this.state = {
            body: '',
            submit: false,
            awaiting: false
        }
        this.saveItem = this.saveItem.bind(this);
        this.bodyChange = this.bodyChange.bind(this);
    }
    bodyChange(editor, data, value) {
        let submit = !(value === '');
        this.setState({ body: value, submit: submit });
    }

    saveItem() {
        let { props, state } = this;

        this.props.setSpinner(true);
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

        let data = {
            "edit-item": {
                who: props.ship,
                stak: props.stackId,
                name: props.itemId,
                title: props.title,
                perm: permissions,
                content: state.body,


            },
        };

        this.setState({
            awaitingEdit: {
                ship: this.state.ship,
                stackId: this.props.stackId,
                itemId: this.props.itemId,
            }
        }, () => {
            this.props.api.action("srrs", "srrs-action", data)
        });
    }
    componentDidMount() {
        const { props } = this;
        let stack = props.pubs[props.stackId];
        let content = stack.items[props.itemId].content;
        let file = content.file;
        let body = file.slice(file.indexOf(';>') + 3);
        this.setState({ body: body, stack: stack });
    }


    render() {
        const { props, state } = this
        const options = {
            mode: 'markdown',
            theme: 'tlon',
            lineNumbers: false,
            lineWrapping: true,
            scrollbarStyle: null,
            cursorHeight: 0.85
        };

        /* let stackLinkText = `<- Back to ${this.state.stack.info.title}`; */
        let title = props.stack.info.title;
        let date = dateToDa(new Date(props.item.content["date-created"]));
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
                        onClick={this.saveItem}>
                        Save "{title}"
                    </button>
                    <Link to={`/~srrs/${props.stack.info.owner}/${props.stack.info.filename}`} className="blue3 ml2">
                        {`<- ${props.stack.info.filename}`}
                    </Link>
                </div>
                <div className="mw6 center">
                    <div className="pl4">
                        <div className="gray2">{date}</div>
                    </div>
                    <div className="EditItem">
                        <CodeMirror
                            value={state.body}
                            options={options}
                            onBeforeChange={(e, d, v) => this.bodyChange(e, d, v)}
                            onChange={(editor, data, value) => { }}
                        />
                        <Spinner text="Editing item..." awaiting={this.state.awaiting} classes="absolute bottom-1 right-1 ba b--gray1-d pa2" />
                    </div>
                </div>
            </div>
        );
    }
}