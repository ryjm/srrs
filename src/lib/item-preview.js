import React, { Component } from 'react';
import moment from 'moment';
import { Link } from 'react-router-dom';
import { ItemSnippet } from '~/lib/item-snippet';
import { TitleSnippet } from '~/lib/title-snippet';
import momentConfig from '~/config/moment';

export class ItemPreview extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale('en', momentConfig);
    this.saveGrade = this.saveGrade.bind(this);
  }

  saveGrade() {
    this.props.setSpinner(true);
    const data = {
      'answered-item': {
        stak: this.props.stackId,
        item: this.props.itemId,
        answer: this.state.recallGrade
      }
    };
    this.setState({
      awaitingGrade: {
        ship: this.state.ship,
        stackId: this.props.stackId,
        itemId: this.props.itemId
      }
    }, () => {
      this.props.api.action('srrs', 'srrs-action', data);
    });
  };
  render() {
    const date = moment(this.props.item.date).fromNow();
    const author = this.props.item.author;

    const stackLink = '/~srrs/' +
      this.props.item.stackOwner + '/' +
      this.props.item.stackName;
    const itemLink = stackLink + '/' + this.props.item.itemName;

    return (
      <div className="mv2 link black dim db mw5 pa2 br2 bt b--green0 shadow-hover ma2">
        <Link to={{ pathname: itemLink, state: { prevPath: location.pathname } }}>
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
