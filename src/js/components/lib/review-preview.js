
import React, { Component } from 'react';
import moment from 'moment';
import { Link } from 'react-router-dom';
import { ItemSnippet } from '/components/lib/item-snippet';
import momentConfig from '/config/moment';

export class ReviewPreview extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale('en', momentConfig);
  }

  render() {
    const date = moment(this.props.item.date).fromNow();
    const author = this.props.item.author;
    const stackLink =
      '/~srrs/' + this.props.item.author + '/' + this.props.item.stackName;
    const itemLink = stackLink + '/' + this.props.item.itemName;
    const loc = {
      pathname: itemLink,
      state: { mode: 'review',
              prevPath: location.pathname }
    };
    return (
      <div className="f9 lh-solid ml3 flex">
        <div className="flex-wrap">
          <div className="mv2 link black dim db mw5 pa2 br2 bt b--green0 shadow-hover ma2">
            <Link to={loc}>
              <ItemSnippet body={this.props.item.itemSnippet} />
            </Link>
            <div className="flex">
              <div className="gray2 mr3">{author}</div>
              <div className="gray2 mr2">{date}</div>
             <Link to={stackLink} >
              <div className="blue3 mr2">{this.props.item.stackTitle}</div>
             </Link>

            </div>
          </div>
        </div>
      </div>
    );
  }
}
