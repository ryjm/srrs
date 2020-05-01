import React, { Component } from 'react';
import classnames from 'classnames';
import { Link } from 'react-router-dom';
import { PathControl } from '/components/lib/path-control';
import { withRouter } from 'react-router';
import urbitOb from 'urbit-ob';
import { stringToSymbol } from '/lib/util';

const PC = withRouter(PathControl);

class FormLink extends Component {
  render(props){
    if (this.props.enabled) {
      return (
        <button className="body-large b z-2 pointer" onClick={this.props.action}>
          {this.props.body}
        </button>
      );
    }
    return (
      <p className="gray-30 b body-large">{this.props.body}</p>
    );
  }
}

export class NewStack extends Component {
  constructor(props){
    super(props);

    this.state = {
      title: '',
      page: 'main',
      awaiting: false
    };
    this.titleChange = this.titleChange.bind(this);
    this.firstItem = this.firstItem.bind(this);
    this.returnHome = this.returnHome.bind(this);
    this.stackSubmit = this.stackSubmit.bind(this);

    this.titleHeight = 52;
  }

  stackSubmit() {
    let ship = window.ship;
    let stackTitle = this.state.title;
    let stackId = stringToSymbol(stackTitle);

    let permissions = {
      read: {
        mod: 'black',
        who: [],
      },
      write: {
        mod: 'white',
        who: [],
      }
    }

    let makeStack = {
      "new-stack" : {
        name: stackId,
        title: stackTitle,
        items: null,
        edit: "all",
        perm: permissions
      },
    };

    this.setState({
      awaiting: stackId
    });
    
    this.props.setSpinner(true);

    this.props.api.action("srrs", "srrs-action", makeStack);
    // this.props.api.action("srrs", "srrs-action", sendInvites);
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.awaiting) {
      if (this.props.pubs[this.state.awaiting]) {
        this.props.setSpinner(false);

        if (this.state.redirect === 'new-item') {
          this.props.history.push("/~srrs/new-item",
            {
              lastParams: {
                ship: `~${window.ship}`,
                stack: this.state.awaiting,
              }
            }
          );
        } else if (this.state.redirect === 'home') {
          this.props.history.push(
            `/~srrs/~${window.ship}/${this.state.awaiting}`);
        }
      }
    }
  }

  titleChange(evt){
    this.titleInput.style.height = 'auto';
    this.titleInput.style.height =  (this.titleInput.scrollHeight < 52)
      ?  52 : this.titleInput.scrollHeight;
    this.titleHeight = this.titleInput.style.height;

    this.setState({title: evt.target.value});
  }


  firstItem() {
    this.setState({redirect: "new-item"});
    this.stackSubmit();
  }

  returnHome() {
    this.setState({redirect: "home"});
    this.stackSubmit();
  }

  render() {
    if (this.state.page === 'main') {
      return (
        <div>
          <PC pathData={false} {...this.props}/>
          <div className="absolute w-100"
               style={{height: 'calc(100% - 124px)', top: 124}}>
            <div className="h-inner dt center mw-688 w-100">
              <div className="flex-col dtc v-mid">
                <textarea autoFocus
                  ref={(el) => {this.titleInput = el}}
                  className="header-2 b--none w-100"
                  style={{resize:"none", height: this.titleHeight}}
                  rows={1}
                  type="text"
                  name="stackName"
                  placeholder="Add a Title"
                  onChange={this.titleChange}>
                </textarea>

                <hr className="gray-30" style={{marginTop:32, marginBottom: 32}}/>

                <FormLink
                  enabled={(this.state.title !== '')}
                  action={this.firstItem}
                  body={"-> Create"}
                />

                <hr className="gray-30" style={{marginTop:32, marginBottom: 32}}/>

                <Link to="/~srrs/review" className="body-large b">
                  Cancel
                </Link>
              </div>
            </div>
          </div>
        </div>
      );
    } else if (this.state.page === 'addInvites') {
      let enableButtons = ((this.state.title !== '') && this.state.validInvites);
      let invitesStyle = (this.state.validInvites)
        ?  "body-regular-400 b--none w-100"
        :  "body-regular-400 b--none w-100 red";

      return (
        <div>
          <PC pathData={false} {...this.props}/>
          <div className="absolute w-100"
               style={{height: 'calc(100% - 124px)', top: 124}}>
            <div className="h-inner dt center mw-688 w-100">
              <div className="flex-col dtc v-mid">
                <textarea autoFocus
                  ref={(el) => {this.titleInput = el}}
                  className="header-2 b--none w-100"
                  style={{resize:"none", height: this.titleHeight}}
                  rows={1}
                  type="text"
                  name="stackName"
                  placeholder="Add a Title"
                  onChange={this.titleChange}>
                </textarea>

                <hr className="gray-30" style={{marginTop:32, marginBottom: 32}}/>

                <FormLink
                  enabled={enableButtons}
                  action={this.firstItem}
                  body={"-> Save"}
                />

                <hr className="gray-30" style={{marginTop:32, marginBottom: 32}}/>

                <FormLink
                  enabled={enableButtons}
                  action={this.returnHome}
                  body={"-> Save and return home"}
                />

                <hr className="gray-30" style={{marginTop:32, marginBottom: 32}}/>

                <Link to="/~srrs/review" className="body-large b">
                  Cancel
                </Link>
              </div>
            </div>
          </div>
        </div>
      );

    }
  }
}
