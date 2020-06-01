import React, { Component } from 'react';
import moment from 'moment';
import { Link } from 'react-router-dom';
import { ItemBody } from '/components/lib/item-body';
import { EditItem } from '/components/edit-item';
import { Recall } from '/components/recall';
import { NotFound } from '/components/not-found';
import { withRouter } from 'react-router';
import _ from 'lodash';

const NF = withRouter(NotFound);

export class Item extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale('en', {
      relativeTime: {
        past: function (input) {
          return input === 'just now'
            ? input
            : input + ' ago'
        },
        s: 'just now',
        future: 'in %s',
        m: '1m',
        mm: '%dm',
        h: '1h',
        hh: '%dh',
        d: '1d',
        dd: '%dd',
        M: '1 month',
        MM: '%d months',
        y: '1 year',
        yy: '%d years',
      }
    });

    this.state = {
      mode: 'view',
      title: '',
      bodyFront: '',
      bodyBack: '',
      learn: [],
      awaitingEdit: false,
      awaitingGrade: false,
      awaitingLoad: false,
      awaitingDelete: false,
      submit: false,
      ship: this.props.ship,
      stackId: this.props.stackId,
      itemId: this.props.itemId,
      stack: null,
      item: null,
      pathData: [],
      temporary: false,
      notFound: false
    }

    if (this.props.location.state) {
      let mode = this.props.location.state.mode;
      if (mode) {
        this.state.mode = mode;
      }
    }


    this.editItem = this.editItem.bind(this);
    this.deleteItem = this.deleteItem.bind(this);
    this.titleChange = this.titleChange.bind(this);
    this.gradeItem = this.gradeItem.bind(this);
    this.setGrade = this.setGrade.bind(this);
    this.saveGrade = this.saveGrade.bind(this);
    this.toggleAdvanced = this.toggleAdvanced.bind(this);
    this.toggleShowBack = this.toggleShowBack.bind(this);

    let ship = this.props.ship;
    let stackId = this.props.stackId;
    let itemId = this.props.itemId;
    if (ship !== window.ship) {
      let stack = _.get(this.props, `subs["${ship}"]["${stackId}"]`, false);

      if (stack) {
        let item = _.get(stack, `items["${itemId}"]`, false);
        let learn = _.get(stack, `items["${itemId}"].learn`, false);
        let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
        let itemUrl = `${stackUrl}/${item.name}`;

        let tempState = {
          title: item.content.title,
          bodyFront: item.content.front,
          bodyBack: item.content.back,
          stack: stack,
          item: item,
          learn: learn,
          pathData: [
            { text: "Home", url: "/~srrs/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.title, url: itemUrl },
          ],
        }
        this.state = {...this.state, ...tempState}

      } else {
        this.state = {...this.state, ...{
          awaitingLoad: {
            ship: ship,
            stackId: stackId,
            itemId: itemId,
          }, ...{temporary: true}}}
      }
    } else {
      let stack = _.get(this.props, `pubs["${stackId}"]`, false);
      let item = _.get(stack, `items["${itemId}"]`, false);
      let learn = _.get(stack, `items["${itemId}"].learn`, false);

      if (!stack || !item) {
        this.state = {...this.state, ...{ notFound: true }}
        return;
      } else {
        let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
        let itemUrl = `${stackUrl}/${item.name}`;

        this.state = {...this.state, ...{
          title: item.content.title,
          bodyFront: item.content.front,
          bodyBack: item.content.back,
          stack: stack,
          item: item,
          learn: learn,
          pathData: [
            { text: "Home", url: "/~srrs/review" },
            { text: stack.info.title, url: stackUrl },
            { text: item.content.title, url: itemUrl },
          ],
        }};
      }
    }
  }

  editItem() {
    this.setState({ mode: 'edit' });
  }

  gradeItem() {
    this.setState({ mode: 'grade' });
  }
  setGrade(value) {
    this.setState({ recallGrade: value });
  }
  toggleAdvanced() {
    if (this.state.mode == 'advanced') {
      this.setState({ mode: 'view' });
    } else {
      this.setState({ mode: 'advanced' });
    }
  }
  toggleShowBack() {
    if (this.state.showBack) {
      this.setState({ showBack: false });
    } else {
      this.setState({ showBack: true });
    }
  }

  saveGrade(value) {
    this.props.setSpinner(true);
    let data = {
      "answered-item": {
        owner: this.props.match.params.ship,
        stak: this.props.stackId,
        item: this.props.itemId,
        answer: value
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
  
  componentDidUpdate(prevProps, prevState) {
    if (this.state.notFound) return;

    let ship = this.props.ship;
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

    if (this.state.learn !== learn) {
      this.state.learn = learn;
    }
    if (this.state.awaitingDelete && (item === false) && oldItem) {
      this.props.setSpinner(false);
      let redirect = `/~srrs/~${this.props.ship}/${this.props.stackId}`;
      this.props.history.push(redirect);
      return;
    }

    if (!stack || !item) {
      this.setState({ notFound: true });
      return;
    }

    if (this.state.awaitingEdit &&
      ((item.content.title != oldItem.title) || (item.content.front != oldItem.content.front) || (item.content.back != oldItem.content.back))) {

      let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
      let itemUrl = `${stackUrl}/${item.name}`;

      this.setState({
        mode: 'view',
        title: item.content.title,
        bodyFront: item.content.front,
        bodyBack: item.content.back,
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

    if (this.state.awaitingGrade) {
      let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
      let itemUrl = `${stackUrl}/${item.name}`;
      let redirect = itemUrl;
      if (this.state.mode === 'review') {
        if (this.props.location.state.prevPath) {
          redirect = this.props.location.state.prevPath;
        } else
        redirect =`/~srrs/review`;
      }

      this.setState({
        awaitingGrade: false,
        mode: 'view',
        item: item

      }, () => {
        this.props.api.fetchStatus(stack.info.filename, item.name)
        this.props.history.push(redirect)
      })


    }
    if (!this.state.temporary) {
      if (oldItem != item) {
        let stackUrl = `/~srrs/${stack.info.owner}/${stack.info.filename}`;
        let itemUrl = `${stackUrl}/${item.name}`;

        this.setState({
          item: item,
          title: item.content.title,
          bodyFront: item.content.front,
          bodyBack: item.content.back,
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
        this.setState({ stack: stack });
      }
    }
  }

  deleteItem() {
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
      this.props.api.action("srrs", "srrs-action", del).then(() => {
       let redirect = `/~srrs/~${this.props.ship}/${this.props.stackId}`;
        this.props.history.push(redirect);
      });
    });
  }

  titleChange(evt) {
    this.setState({ title: evt.target.value });
  }

  gradeChange(evt) {
    this.setState({ recallGrade: evt.target.value });
  }

  render() {
    const { props, state } = this;
    let adminEnabled = (this.props.ship === window.ship);
    if (this.state.notFound) {
      return (
        <NF />
      );
    } else if (this.state.awaitingLoad) {
      return null;
    } else if (this.state.awaitingEdit) {
      return null;
    } else if (this.state.mode == 'review' || this.state.mode == 'view' || this.state.mode == 'grade' || this.state.mode == 'advanced') {
      let title = this.state.item.content.title;
      let stackTitle = this.props.stackId;
      let host = this.state.stack.info.owner;
      let date = moment(this.state.item.content["date-created"]).fromNow();

      return (

        <div className="center mw6 f9 h-100"
          style={{ paddingLeft: 16, paddingRight: 16 }}>
          <div className="h-100 pt0 pt8-m pt8-l pt8-xl no-scrollbar">

            <div
              className="flex justify-between"
              style={{ marginBottom: 32 }}>
              <div className="flex-col">
                <div className="mb1">{title}</div>
                <span>
                  <span className="gray3 mr1">by</span>
                  <span className={"mono"}
                    title={host}>
                    {host}
                  </span>
                </span>
                <Link to={`/~srrs/${host}/${stackTitle}`} className="blue3 ml2">
                  {`<- ${stackTitle}`}
                </Link>

              </div>
              <div className="flex">
                <Link to={`/~srrs/${host}/${stackTitle}/new-item`} className="StackButton bg-light-green green2">
                  New Item
            </Link>
              </div>
            </div>
            <Recall
              enabled={adminEnabled}
              mode={this.state.mode}
              editItem={this.editItem}
              deleteItem={this.deleteItem}
              gradeItem={this.gradeItem}
              setGrade={this.setGrade}
              saveGrade={this.saveGrade}
              toggleAdvanced={this.toggleAdvanced}
              learn={this.state.learn}
              host={host}
            />

            <ItemBody
              bodyFront={this.state.item.content.front}
              bodyBack={this.state.item.content.back}
              showBack={this.state.showBack}
              toggleShowBack={this.toggleShowBack}
            />


          </div>
        </div>

      );

    } else if (this.state.mode == 'edit') {
      return (
        <EditItem
          {...state}
          {...props} />

      );
    }
  }
}

