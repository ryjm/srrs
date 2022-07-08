import React, { Component } from 'react';
import { TitleSnippet } from '~/lib/title-snippet';
import { ItemSnippet } from '~/lib/item-snippet';
import { Link } from 'react-router-dom';
import moment from 'moment';
import momentConfig from '~/config/moment';

class Preview extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale('en', momentConfig);
  }

  buildProps(itemId) {
    const item = this.props.stack.items[itemId];
    return {
      itemTitle: item.content.title,
      itemName: item.name,
      itemBody: item.content.front,
      itemSnippet: item.content.snippet,
      stackTitle: this.props.stack.info.title,
      stackName: this.props.stack.info.filename,
      author: item.content.author,
      stackOwner: this.props.stack.info.owner,
      date: item.content['date-created'],
      pinned: false
    };
  }

  render() {
    if (this.props.itemId) {
      const owner = this.props.stack.info.owner;
      const stackId = this.props.stack.info.filename;
      const previewProps = this.buildProps(this.props.itemId);
      const prevUrl = `/seer/${owner}/${stackId}/${this.props.itemId}`;

      const date = moment(previewProps.date).fromNow();
      const authorDate = `${previewProps.author} • ${date}`;
      const stackLink = '/seer/' +
        previewProps.stackOwner + '/' +
        previewProps.stackName;
      const itemLink = stackLink + '/' + previewProps.itemName;

      return (
        <div className="w-336">
          <Link className="ml2 mr2 gray-50 body-regular db mb3" to={prevUrl}>
            {this.props.text}
          </Link>
          <div className="w-336 relative"
            style={{ height: 210 }}
          >
            <Link to={itemLink} className="db">
              <TitleSnippet badge={false} title={previewProps.itemTitle} />
              <div className="w-100" style={{ height: 16 }}></div>
              <ItemSnippet
                body={previewProps.itemSnippet}
              />
            </Link>
            <p className="label-small gray-50 absolute" style={{ bottom: 0 }}>
              {authorDate}
            </p>
          </div>
        </div>
      );
    } else {
      return (
        <div className="w-336"></div>
      );
    }
  }
}

export class NextPrev extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const items = this.props.stack.order.unpin.slice().reverse();
    const itemIdx = items.indexOf(this.props.itemId);

    const prevId = (itemIdx > 0)
      ?  items[itemIdx - 1]
      :  false;

    const nextId = (itemIdx < (items.length - 1))
      ?  items[itemIdx + 1]
      :  false;

    if (!(prevId || nextId)) {
      return null;
    } else {
      const prevText = '<- previous item';
      const nextText = '-> next item';

      return (
        <div>
          <div className="flex">
            <Preview itemId={prevId} stack={this.props.stack} text={prevText} />
            <div style={{ width: 16 }}></div>
            <Preview itemId={nextId} stack={this.props.stack} text={nextText} />
          </div>
          <hr className="gray-50 w-680 mt4" />
        </div>
      );
    }
  }
}
