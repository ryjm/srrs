import React, { Component } from 'react';

class SaveLink extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (this.props.enabled) {
      return (
        <button className="label-regular b"
          onClick={this.props.action}
        >
          -&gt; Save
        </button>
      );
    } else {
      return (
        <p className="label-regular b gray-50">
          -&gt; Save
        </p>
      );
    }
  }
}

export class StackSettings extends Component {
  constructor(props) {
    super(props);

    this.state = {
      title: '',
      awaitingTitleChange: false
    };

    this.rename = this.rename.bind(this);
    this.titleChange = this.titleChange.bind(this);
    this.deleteStack = this.deleteStack.bind(this);
  }

  rename() {
    const edit = {
      'edit-stack': {
        name: this.props.stackId,
        title: this.state.title
      }
    };
    this.setState({
      awaitingTitleChange: true
    }, () => {
      this.props.api.action('srrs', 'srrs-action', edit);
    });
  }

  titleChange(evt) {
    this.setState({ title: evt.target.value });
  }

  deleteStack() {
    const del = {
      'delete-stack': {
        stack: this.props.stackId
      }
    };
    this.props.api.action('srrs', 'srrs-action', del);
    this.props.history.push('/~srrs/review');
  }

  componentDidUpdate(prevProps) {
    if (this.state.awaitingTitleChange) {
      if (prevProps.title !== this.props.title) {
        this.titleInput.value = '';
        this.setState({
          awaitingTitleChange: false
        });
      }
    }
  }

  render() {
    const back = '<- Back to notes';
    const enableSave = ((this.state.title !== '') &&
      (this.state.title !== this.props.title) &&
      !this.state.awaitingTitleChange);
    return (
      <div className="flex-col mw-688" style={{ marginTop:48 }}>
        <hr className="gray-30" style={{ marginBottom:25 }} />
        <p className="label-regular pointer b" onClick={this.props.back}>
          {back}
        </p>
        <p className="body-large b" style={{ marginTop:16, marginBottom: 20 }}>
          Settings
        </p>
        <div className="flex">
          <div className="flex-col w-100">
            <p className="body-regular-400">Delete Notebook</p>
            <p className="gray-50 label-small-2" style={{ marginTop:12, marginBottom:8 }}>
              Permanently delete this notebook
            </p>
            <button className="red label-regular b" onClick={this.deleteStack}>
              -&gt; Delete
            </button>
          </div>
          <div className="flex-col w-100">
            <p className="body-regular-400">Rename</p>
            <p className="gray-50 label-small-2" style={{ marginTop:12, marginBottom:23 }}>
              Change the name of this notebook
            </p>
            <p className="label-small-2">Notebook Name</p>
            <input className="body-regular-400 w-100"
              ref={(el) => {
 this.titleInput = el;
}}
              style={{ marginBottom:8 }}
              placeholder={this.props.title}
              onChange={this.titleChange}
              disabled={this.state.awaitingTitleChange}
            />
            <SaveLink action={this.rename} enabled={enableSave} />
          </div>
        </div>
      </div>
    );
  }
}
