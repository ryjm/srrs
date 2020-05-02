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
  }

  render() {
    let date = moment(this.props.item.date).fromNow();
    let authorDate = `${this.props.item.author} • ${date}`
    let stackLink = "/~srrs/" +
      this.props.item.stackOwner + "/" +
      this.props.item.stackName;
    let itemLink = stackLink + "/" + this.props.item.itemName;

    return (
      <div className="h-100">
              <div className="h-100 flex flex-column items-center pa4">
              <div className="w-100 mw6">
            <div className="flex flex-column">
        <Link to={itemLink}>
          <TitleSnippet title={this.props.item.itemTitle}/>
          <ItemSnippet
            body={this.props.item.itemSnippet}
          />
        </Link>
                </div>
      </div>
      </div>
      </div>
    );
  }
}
