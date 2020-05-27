import React, { Component } from 'react';
import classnames from 'classnames';
import { TitleSnippet } from '/components/lib/title-snippet';
import { ItemSnippet } from '/components/lib/item-snippet';
import { Link } from 'react-router-dom';
import moment from 'moment';

class Preview extends Component {
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
  }

  buildProps(itemId){
    let item = this.props.stack.items[itemId];
    return {
      itemTitle: item.content.title,
      itemName: item.name,
      itemBody: item.content.front,
      itemSnippet: item.content.snippet,
      stackTitle: this.props.stack.info.title,
      stackName: this.props.stack.info.filename,
      author: item.content.author,
      stackOwner: this.props.stack.info.owner,
      date: item.content["date-created"],
      pinned: false,
    }
  }

  render(){
    if (this.props.itemId) {
      let owner = this.props.stack.info.owner;
      let stackId = this.props.stack.info.filename;
      let previewProps = this.buildProps(this.props.itemId);
      let prevUrl = `/~srrs/${owner}/${stackId}/${this.props.itemId}`

      let date = moment(previewProps.date).fromNow();
      let authorDate = `${previewProps.author} • ${date}`
      let stackLink = "/~srrs/" +
        previewProps.stackOwner + "/" +
        previewProps.stackName;
      let itemLink = stackLink + "/" + previewProps.itemName;

      return (
        <div className="w-336">
          <Link className="ml2 mr2 gray-50 body-regular db mb3" to={prevUrl}>
            {this.props.text}
          </Link>
          <div className="w-336 relative"
            style={{height:210}}>
            <Link to={itemLink} className="db">
              <TitleSnippet badge={false} title={previewProps.itemTitle} />
              <div className="w-100" style={{height:16}}></div>
              <ItemSnippet
                body={previewProps.itemSnippet}
              />
            </Link>
            <p className="label-small gray-50 absolute" style={{bottom:0}}>
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
    let items = this.props.stack.order.unpin.slice().reverse();
    let itemIdx = items.indexOf(this.props.itemId);

    let prevId = (itemIdx > 0)
      ?  items[itemIdx - 1]
      :  false;

    let nextId = (itemIdx < (items.length - 1))
      ?  items[itemIdx + 1]
      :  false;

    if (!(prevId || nextId)){
      return null;
    } else {
      let prevText = "<- Previous Item";
      let nextText = "-> Next Item";

      return (
        <div>
          <div className="flex">
            <Preview itemId={prevId} stack={this.props.stack} text={prevText}/>
            <div style={{width:16}}></div>
            <Preview itemId={nextId} stack={this.props.stack} text={nextText}/>
          </div>
          <hr className="gray-50 w-680 mt4"/>
        </div>
      );
    }
  }
}
