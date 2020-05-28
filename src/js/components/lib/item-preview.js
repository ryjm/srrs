import React, { Component } from 'react';
import classnames from 'classnames';
import moment from 'moment';
import { Link } from 'react-router-dom';
import { ItemSnippet } from '/components/lib/item-snippet';
import { TitleSnippet } from '/components/lib/title-snippet';

export class ItemPreview extends Component {
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
    this.saveGrade = this.saveGrade.bind(this);
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
  };
  render() {
    let date = moment(this.props.item.date).fromNow();
    let author = this.props.item.author

    let stackLink = "/~srrs/" +
      this.props.item.stackOwner + "/" +
      this.props.item.stackName;
    let itemLink = stackLink + "/" + this.props.item.itemName;

    return (
      <div className="mv2 link black dim db mw5 pa2 br2 bt b--green0 shadow-hover ma2">
        <Link to={{pathname: itemLink, state: {prevPath: location.pathname}}}>
          <TitleSnippet title={this.props.item.itemTitle} />
          <ItemSnippet
            body={this.props.item.itemSnippet}
          />
        </Link>
        <div className="flex">
          <div className="gray2 mr3">{author}</div>
          <div className="gray2 mr2">{date}</div>
        </div>

      </div>

    );
  }
}
