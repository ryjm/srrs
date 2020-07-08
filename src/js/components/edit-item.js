import React, { Component } from 'react';
import { Controlled as CodeMirror } from 'react-codemirror2';
import { Link } from 'react-router-dom';
import { dateToDa } from '/lib/util';
import 'codemirror/mode/markdown/markdown';

export class EditItem extends Component {
    constructor(props) {
        super(props);
        this.state = {
            bodyFront: '',
            bodyBack: '',
            title: '',
            submit: false,
            awaiting: false
        }
        this.saveItem = this.saveItem.bind(this);
        this.titleChange = this.titleChange.bind(this);
        this.bodyFrontChange = this.bodyFrontChange.bind(this);
        this.bodyBackChange = this.bodyBackChange.bind(this);
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
                title: state.title,
                perm: permissions,
                front: state.bodyFront,
                back: state.bodyBack,


            },
        };

        this.setState({
            awaitingEdit: {
                ship: this.state.ship,
                stackId: this.props.stackId,
                itemId: this.props.itemId,
            }
        }, () => {
            this.props.api.action("srrs", "srrs-action", data).then(() => {
                this.setState({awaiting: false, mode: 'view'});
                let redirect = `/~srrs/~${props.ship}/${props.stackId}`;
                props.history.push(redirect);
            });
        });
    }
    componentDidMount() {
        const { props } = this;
        let stack = props.pubs[props.stackId];
        let content = stack.items[props.itemId].content;
        let title = content.title
        let front = content.front;
        let back = content.back;
        let bodyFront = front.slice(front.indexOf(';>') + 3);
        let bodyBack = back.slice(back.indexOf(';>') + 3);
        this.setState({ bodyFront: bodyFront, bodyBack: bodyBack, stack: stack, title: title });
    }


    render() {
        const { props, state } = this
        const options = {
            mode: 'markdown',
            theme: 'tlon',
            lineNumbers: false,
            lineWrapping: true,
            cursorHeight: 0.85
        };

        /* let stackLinkText = `<- Back to ${this.state.stack.info.title}`; */
        let stackTitle = props.stack.info.title;
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
                        Save "{props.title}"
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
                            value={state.title}
                            options={options}
                            onBeforeChange={(e, d, v) => this.titleChange(e, d, v)}
                            onChange={(editor, data, value) => { }}
                        />
                    </div>
                    <div className="EditItem">
                        <CodeMirror
                            value={state.bodyFront}
                            options={options}
                            onBeforeChange={(e, d, v) => this.bodyFrontChange(e, d, v)}
                            onChange={(editor, data, value) => { }}
                        />
                    </div>
                    <div className="EditItem">
                        <CodeMirror
                            value={state.bodyBack}
                            options={options}
                            onBeforeChange={(e, d, v) => this.bodyBackChange(e, d, v)}
                            onChange={(editor, data, value) => { }}
                        />
                    </div>
                </div>
            </div>
        );
    }
}