import React, { Component } from 'react';
import classnames from 'classnames';
import { ReviewPreview } from '/components/lib/review-preview';
import { withRouter } from 'react-router';
import { HeaderMenu } from '/components/lib/header-menu';

const HM = withRouter(HeaderMenu);

export class Review extends Component {
  constructor(props){
    super(props)
  }

  buildReview() {
    var review = [];
    var group = {
      date: new Date(),
      items: [],
    };

    for (var i=0; i<this.props.review.length; i++) {
      let index = this.props.review[i];
      let item = this.retrieveItem(index.item, index.stack, index.who);
      let itemDate = new Date(item.content["date-created"]);
      let itemProps = this.buildItemPreviewProps(index.item, index.stack, index.who);

      if (group.items.length == 0) {
        group = {
          date: this.roundDay(itemDate),
          items: [itemProps],
        }
      } else if ( this.sameDay(group.date, itemDate) ) {
        group.items.push(itemProps) ;
      } else {
        review.push(Object.assign({}, group));
        group = {
          date: this.roundDay(itemDate),
          items: [itemProps],
        }
      }

      if (i == (this.props.review.length - 1)) {
        review.push(Object.assign({}, group));
      }
    }
    return review;
  }

  buildItemPreviewProps(it, st, who){
    let item = this.retrieveItem(it, st, who);
    let stack = this.retrieveStack(st, who);

    return {
      itemTitle: item.content.title,
      itemName:  item.content['note-id'],
      itemBody: item.content.file,
      stackTitle: stack.title,
      stackName:  stack.filename,
      author: item.content.author.slice(1),
      stackOwner: who,
      date: item.content["date-created"]
    }

  }


  retrieveItem(item, stack, who) {
    if (who === window.ship) {
      return this.props.pubs[stack].items[item];
    } else {
      return this.props.subs[who][stack].items[item];
    }
  }

  retrieveStack(stack, who) {
    if (who === window.ship) {
      return this.props.pubs[stack].info;
    } else {
      return this.props.subs[who][stack].info;
    }
  }



  roundDay(d) {
    let result = new Date(d.getTime());
    result.setHours(0);
    result.setMinutes(0);
    result.setSeconds(0);
    result.setMilliseconds(0);
    return result
  }

  sameDay(d1, d2) {
    return d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate() &&
      d1.getFullYear() === d2.getFullYear();
  }

  dateLabel(d) {
    let today = new Date();

    let yesterday = new Date(today.getTime() - (1000*60*60*24));
    if (this.sameDay(d, today)) {
      return "Today";
    } else if (this.sameDay(d, yesterday)) {
      return "Yesterday";
    } else if ( d.getFullYear() === today.getFullYear() ) {
      let month = d.toLocaleString('en-us', {month: 'long'});
      let day = d.getDate();
      return month + ' ' + day;
    } else {
      let month = d.toLocaleString('en-us', {month: 'long'});
      let day = d.getDate();
      let year = d.getFullYear();
      return month + ' ' + day + ' ' + year;
    }
  }

  render() {
    let review = this.buildReview();

    let body = review.map((group, i) => {
      let items = group.items.map((item, j) => {
        return (
          <ReviewPreview
            item={item}
            key={j}
          />
        );
      });
      let date = this.dateLabel(group.date);
      return (
        <div key={i}>
          <div className="w-100">
            <h2 className="gray-50" style={{marginBottom:8}}>
              {date}
            </h2>
          </div>
          <div className="flex flex-wrap">
            {items}
          </div>
        </div>
      );
    });

    return (
      <div>
        <HM />
        <div className="absolute w-100"
          style={{top:124, marginLeft: 16, marginRight: 16, marginTop: 32}}>
          <div className="flex-col">
            {body}
          </div>
        </div>
      </div>
    );
  }
}
