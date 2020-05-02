import React, { Component } from 'react';
import classnames from 'classnames';
import cx from 'classnames-es';
import moment from 'moment';
import { SrrsCreate } from '/components/lib/srrs-create';
import { Link } from 'react-router-dom';
import { ItemBody } from '/components/lib/item-body';
import { PathControl } from '/components/lib/path-control';
import { NextPrev } from '/components/lib/next-prev';
import { NotFound } from '/components/not-found';
import { withRouter } from 'react-router';
import Choices from 'react-choices'
import _ from 'lodash';

const NF = withRouter(NotFound);
const PC = withRouter(SrrsCreate);
class Admin extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (!this.props.enabled){
      return null;
    } else if (this.props.mode === 'view'){
      return (

        <div className="flex-col fr">

          <p className="label-regular gray-50 pointer tr b"
            onClick={this.props.gradeItem}>
            Grade
          </p>

          <p className="label-regular gray-50 pointer tr b"
             onClick={this.props.editItem}>
            Edit
          </p>
          <p className="label-regular red pointer tr b"
             onClick={this.props.deleteItem}>
            Delete
          </p>
          <p className="label-regular gray-50 pointer tr b"
             onClick={this.props.toggleAdvanced}>
            Advanced
          </p>
        </div>
      );
    } else if (this.props.mode === 'edit'){
      return (
        <div className="flex">
          <p className="pointer"
             onClick={this.props.saveItem}>
            -> Save
          </p>
          <p className="pointer"
             onClick={this.props.deleteItem}>
            Delete item
          </p>
        </div>
      );
    } else if (this.props.mode === 'grade'){
      let modifyButtonClasses = "mt4 db f9 ba pa2 white-d bg-gray0-d b--black b--gray2-d pointer";
      return (
        <div className="flex">
        
        <Choices
            name="recall_grade"
            label="grade"
            availableStates={[
              { value: 'again' },
              { value: 'hard' },
              { value: 'good' },
              { value: 'easy' }
            ]}
            defaultValue="again"
          >
            {({
              name,
              label,
              states,
              selectedValue,
              setValue,
              hoverValue
            }) => (
                 
                <div
                  className="choices"
                >
                  <p className="pointer"
                    onClick={this.props.saveGrade}>
                    ->  Save Grade
                  </p>

                  <div className="choices__items">
                    {states.map((state, idx) => (
                      <button
                        key={`choice-${idx}`}
                        id={`choice-${state.value}`}
                        tabIndex={state.selected ? 0 : -1}
                        className={classnames('choice', state.inputClassName, {
                          'choice--focused': state.focused,
                          'outline-m': state.hovered,
                          'bg-green': state.selected
                        }, modifyButtonClasses)}
                        onMouseOver={hoverValue.bind(null, state.value)}
                        onClick={() => {
                          setValue(state.value);
                          this.props.setGrade(state.value);
                        }
                        }
                      >
                        {state.label}
                      </button>
                    ))}
                  </div>
                </div>
              )}
          </Choices>
          </div>
      );
    } else if (this.props.mode === 'advanced') {
      let ease = `ease: ${this.props.learn.ease}`;
      let interval = `interval: ${this.props.learn.interval}`;
      let box = `box: ${this.props.learn.box}`;
      let backString = `<- Back`

      return (
        <div className="body-regular flex-col fr">
          <p className="pointer"
            onClick={this.props.toggleAdvanced}>
            {backString}
          </p>
          <p className="label-small gray-50">{ease}</p>
          <p className="label-small gray-50">{interval}</p>
          <p className="label-small gray-50">{box}</p>
        </div>
      );
    }

  }
}

export class Item extends Component {
  constructor(props){
    super(props);

    moment.updateLocale('en', {
      relativeTime: {
        past: function(input) {
          return input === 'just now'
            ? input
            : input + ' ago'
        },
        s : 'just now',
        future : 'in %s',
        m  : '1m',
        mm : '%dm',
        h  : '1h',
        hh : '%dh',
        d  : '1d',
        dd : '%dd',
        M  : '1 month',
        MM : '%d months',
        y  : '1 year',
        yy : '%d years',
      }
    });

    this.state = {
      mode: 'view',
      titleOriginal: '',
      bodyOriginal: '',
      title: '',
      body: '',
      recallGrade: '',
      learn: [],
      awaitingEdit: false,
      awaitingGrade: false,
      awaitingLoad: false,
      awaitingDelete: false,
      ship: this.props.ship,
      stackId: this.props.stackId,
      itemId: this.props.itemId,
      stack: null,
      item: null,
      pathData: [],
      temporary: false,
      notFound: false,
    }

    this.editItem = this.editItem.bind(this);
    this.deleteItem = this.deleteItem.bind(this);
    this.saveItem = this.saveItem.bind(this);
    this.titleChange = this.titleChange.bind(this);
    this.bodyChange = this.bodyChange.bind(this);
    this.gradeItem = this.gradeItem.bind(this);
    this.setGrade = this.setGrade.bind(this);
    this.saveGrade = this.saveGrade.bind(this);
    this.toggleAdvanced = this.toggleAdvanced.bind(this);

  }

  editItem() {
    this.setState({mode: 'edit'});
  }

  gradeItem() {
    this.setState({mode: 'grade'});
  }
  setGrade(value) {
    this.setState({recallGrade: value});
  }
  toggleAdvanced() {
    if (this.state.mode == 'advanced') {
      this.setState({mode: 'view'});
    } else {
      this.setState({mode: 'advanced'});
    }
  }
  saveItem() {
    if (this.state.title == this.state.titleOriginal &&
        this.state.body == this.state.bodyOriginal) {
      this.setState({mode: 'view'});
      return;
    }

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
        who: this.state.ship,
        stack: this.props.stackId,
        name: this.props.itemId,
        title: this.state.title,
        perm: permissions,
        content: this.state.body,

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
  saveGrade() {
    this.props.setSpinner(true);
    let data = {
      "answered-item": {
        stak: this.props.stackId,
        item: this.props.itemId,
        answer: this.state.recallGrade
      },
    };
    this.setState({
      awaitingGrade: {
        ship: this.state.ship,
        stackId: this.props.stackId,
        itemId: this.props.itemId,
      }
    }, () => {
      this.props.api.action("srrs", "srrs-action", data)
    });
  }

  componentWillMount() {
    let ship = this.props.ship;
    let stackId = this.props.stackId;
    let itemId = this.props.itemId;

    if (ship !== window.ship) {
      let stack = _.get(this.props, `subs["${ship}"]["${stackId}"]`, false);

      if (stack) {
        let item = _.get(stack, `items["${itemId}"]`, false);
        let learn = _.get(stack, `items["${itemId}"].learn`, false);
        let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
        let itemUrl = `${stackUrl}/${item.content["note-id"]}`;

        this.setState({
          titleOriginal: item.content.title,
          bodyOriginal: item.content.file,
          title: item.content.title,
          body: item.content.file,
          stack: stack,
          item: item,
          learn: learn,
          pathData: [
            { text: "Home", url: "/~srrs/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.title, url: itemUrl },
          ],
        });

        let read = {
          read: {
            who: ship,
            stack: stackId,
            item: itemId,
          }
        };
        this.props.api.action("srrs", "srrs-action", read);

      } else {
        this.setState({
          awaitingLoad: {
            ship: ship,
            stackId: stackId,
            itemId: itemId,
          },
          temporary: true,
        });

        this.props.setSpinner(true);

        this.props.api.bind(`/stack/${stackId}`, "PUT", ship, "srrs",
          this.handleEvent.bind(this),
          this.handleError.bind(this));
      }
    } else {
      let stack = _.get(this.props, `pubs["${stackId}"]`, false);
      let item = _.get(stack, `items["${itemId}"]`, false);
      let learn = _.get(stack, `items["${itemId}"].learn`, false);

      if (!stack || !item) {
        this.setState({notFound: true});
        return;
      } else {
        let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
        let itemUrl = `${stackUrl}/${item.content["note-id"]}`;

        this.setState({
          titleOriginal: item.content.title,
          bodyOriginal: item.content.file,
          title: item.content.title,
          body: item.content.file,
          stack: stack,
          item: item,
          learn: learn,
          pathData: [
            { text: "Home", url: "/~srrs/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.content.title, url: itemUrl },
          ],
        });
      }
    }
  }

  handleEvent(diff) {
    console.log("handle event")
    console.log(diff)
    if (diff.data.total) {
      let stack = diff.data.total.data;
      let item = stack.items[this.state.itemId].item;
      let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
      let itemUrl = `${stackUrl}/${item.content["note-id"]}`;

      this.setState({
        awaitingLoad: false,
        titleOriginal: item.content.title,
        bodyOriginal: item.content.file,
        title: item.content.title,
        body: item.content.file,
        stack: stack,
        item: item,
        pathData: [
          { text: "Home", url: "/~srrs/review" },
          { text: stack.info.title, url: stackUrl },
          { text: item.info.title, url: itemUrl },
        ],
      });

      this.props.setSpinner(false);

    } else if (diff.data.stack) {
      let newStack = this.state.stack;
      newStack.info = diff.data.stack.data;
      this.setState({
        stack: newStack,
      });
    } else if (diff.data.item) {
      this.setState({
        item: diff.data.item.data,
      });
    } else if (diff.data.remove) {
      // XX TODO Handle this properly
    }
  }

  handleError(err) {
    this.props.setSpinner(false);
    this.setState({notFound: true});
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.notFound) return;

    let ship   = this.props.ship;
    let stackId = this.props.stackId;
    let itemId = this.props.itemId;

    let oldItem = prevState.item;
    let oldStack = prevState.stack;


    let item;
    let stack;
    let learn;

    if (ship === window.ship) {
      stack = _.get(this.props, `pubs["${stackId}"]`, false);
      item = _.get(stack, `items["${itemId}"]`, false);
      learn = _.get(stack, `items["${itemId}"].learn`, false);
    } else {
      stack = _.get(this.props, `subs["${ship}"]["${stackId}"]`, false);
      item = _.get(stack, `items["${itemId}"]`, false);
      learn = _.get(stack, `items["${itemId}"].learn`, false);
    }

    if (this.state.learn !== this.props.learn) {
      this.state.learn = this.props.learn;
    }
    if (this.state.awaitingDelete && (item === false) && oldItem) {
      this.props.setSpinner(false);
      let redirect = `/~srrs/~${this.props.ship}/${this.props.stackId}`;
      this.props.history.push(redirect);
      return;
    }

    if (!stack || !item) {
      this.setState({notFound: true});
      return;
    }

    if (this.state.awaitingEdit &&
       ((item.content.title != oldItem.title) ||
        (item.content.raw != oldItem.raw))) {

      let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
      let itemUrl = `${stackUrl}/${item.content["note-id"]}`;

      this.setState({
        mode: 'view',
        titleOriginal: item.content.title,
        bodyOriginal: item.content.file,
        title: item.content.title,
        body: item.content.file,
        awaitingEdit: false,
        item: item,
        pathData: [
          { text: "Home", url: "/~srrs/review" },
          { text: stack.info.title, url: stackUrl },
          { text: item.content.title, url: itemUrl },
        ],
      });

      this.props.setSpinner(false);

      let read = {
        read: {
          who: ship,
          stak: stackId,
          item: itemId,
        }
      };
      this.props.api.action("srrs", "srrs-action", read);
    }

    if (this.state.awaitingGrade ) {
     let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
     let itemUrl = `${stackUrl}/${item.content["note-id"]}`;
     this.props.api.fetchStatus(stack.info.filename, item.content.title)
     this.setState({
       mode: 'view',
       titleOriginal: item.content.title,
       bodyOriginal: item.content.file,
       title: item.content.title,
       body: item.content.file,
       awaitingGrade: false,
       item: item,
       pathData: [
         { text: "Home", url: "/~srrs/review" },
         { text: stack.info.title, url: stackUrl },
         { text: item.content.title, url: itemUrl },
       ],
     });

     this.props.setSpinner(false);

     let read = {
       read: {
         who: ship,
         stak: stackId,
         item: itemId,
       }
     };
     this.props.api.action("srrs", "srrs-action", read);
   }
    if (!this.state.temporary){
      if (oldItem != item) {
        let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
        let itemUrl = `${stackUrl}/${item.content["note-id"]}`;

        this.setState({
          titleOriginal: item.content.title,
          bodyOriginal: item.content.file,
          item: item,
          title: item.content.title,
          body: item.content.file,
          pathData: [
            { text: "Home", url: "/~srrs/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.content.title, url: itemUrl },
          ],
        });

        let read = {
          read: {
            who: ship,
            stak: stackId,
            item: itemId,
          }
        };
        this.props.api.action("srrs", "srrs-action", read);
      }
      
      if (oldStack != stack) {
        this.setState({stack: stack});
      }
    }
  }

  deleteItem(){
    let del = {
      "delete-item": {
        stak: this.props.stackId,
        item: this.props.itemId,
      }
    };
    this.props.setSpinner(true);
    this.setState({
      awaitingDelete: {
        ship: this.props.ship,
        stackId: this.props.stackId,
        itemId: this.props.itemId,
      }
    }, () => {
      this.props.api.action("srrs", "srrs-action", del);
    });
  }

  titleChange(evt){
    this.setState({title: evt.target.value});
  }

  bodyChange(evt){
    this.setState({body: evt.target.value});
  }

  gradeChange(evt){
    this.setState({recallGrade: evt.target.value});
  }

  render() {
    let adminEnabled = (this.props.ship === window.ship);

    if (this.state.notFound) {
      return (
        <NF/>
      );
    } else if (this.state.awaitingLoad) {
      return null;
    } else if (this.state.awaitingEdit) {
      return null;
    } else if (this.state.mode == 'view' || this.state.mode == 'grade' || this.state.mode == 'advanced') {
      let stackLink = `/~srrs/~${this.state.ship}/${this.props.stackId}`;
      let stackLinkText = `<- Back to ${this.state.stack.info.title}`;

      let date = moment(this.state.item.content["date-created"]).fromNow();
      let authorDate = `${this.state.item.content.author} • ${date}`;
      let create = (this.props.ship === window.ship);

      return (
        
        <div>
           <PC create="item"/>
              <div className="mb4">
                <p className="fl label-small gray-50">{authorDate}</p>
                <Admin
                  enabled={adminEnabled}
                  mode={this.state.mode}
                  editItem={this.editItem}
                  deleteItem={this.deleteItem}
                  gradeItem={this.gradeItem}
                  setGrade={this.setGrade}
                  saveGrade={this.saveGrade}
                  toggleAdvanced={this.toggleAdvanced}
                  learn={this.state.learn}
                />
              </div>

                <ItemBody
                  body={this.state.item.content.file}
                />
            </div>
      );

    } else if (this.state.mode == 'edit') {
      let stackLink = `/~srrs/~${this.state.ship}/${this.props.stackId}`;
      let stackLinkText = `<- Back to ${this.state.stack.info.title}`;

      let date = moment(this.state.item.content["date-created"]).fromNow();
      let authorDate = `${this.state.item.content.author} • ${date}`;
      let create = (this.props.ship === window.ship);
   
      return (
      
        <div>
          <div className="absolute w-100" style={{top:124}}>
            <div className="mw-688 center mt4 flex-col" style={{flexBasis: 688}}>
              <Link to={stackLink}>
                <p className="body-regular">
                  {stackLinkText}
                </p>
              </Link>

              <input autoFocus className="header-2 b--none w-100"
                type="text"
                name="itemName"
                defaultValue={this.state.titleOriginal}
                onChange={this.titleChange}
              />

              <div className="mb4">
                <p className="fl label-small gray-50">{authorDate}</p>
                <Admin
                  enabled={adminEnabled}
                  mode="edit"
                  saveItem={this.saveItem}
                  deleteItem={this.deleteItem}
                />
              </div>

              <textarea className="cb b--none body-regular-400 w-100 h5"
                style={{resize:"none"}}
                type="text"
                name="itemBody"
                onChange={this.bodyChange}
                defaultValue={this.state.bodyOriginal}>
              </textarea>
            </div>
          </div>
        </div>
      );
    }
  }
}

