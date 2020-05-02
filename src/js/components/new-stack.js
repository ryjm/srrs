
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
      let createClasses = "pointer db f9 green2 bg-gray0-d ba pv3 ph4 mv7 b--green2";
    if (!this.state.idName || this.state.disabled) {
      createClasses = "db f9 gray2 ba bg-gray0-d pa2 pv3 ph4 mv7 b--gray3";
    }
      return (
        <div
        className={
          "h-100 w-100 mw6 pa3 pt4 overflow-x-hidden flex flex-column white-d"
        }>
        <div className="w-100 dn-m dn-l dn-xl inter pt1 pb6 f8">
        <Link to="/~srrs/">{"⟵ All Stacks"}</Link>
        </div>
          <PC pathData={false} {...this.props}/>
              <div className="w-100">
              <p className="f8 mt3 lh-copy db">Name</p>
             <p className="  f9 gray2 db mb2 pt1">
            Stack Name
          </p>
                <textarea autoFocus
                  ref={(el) => {this.titleInput = el}}
                  className={"f7 ba bg-gray0-d white-d pa3 db w-100 " +
                  "focus-b--black focus-b--white-d b--gray3 b--gray2-d"}
                  style={{resize:"none"}}
                  rows={1}
                  name="stackName"
                  placeholder="Add a Title"
                  onChange={this.titleChange}>
                </textarea>

                <button
                  disabled={(this.state.title == '')}
                  onClick={this.firstItem}
                  className={createClasses}
>Create</button>

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
