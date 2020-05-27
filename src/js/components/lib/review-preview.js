import React, { Component } from "react";
import classnames from "classnames";
import moment from "moment";
import { Link } from "react-router-dom";
import { ItemSnippet } from "/components/lib/item-snippet";
import { TitleSnippet } from "/components/lib/title-snippet";

export class ReviewPreview extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale("en", {
      relativeTime: {
        past: function (input) {
          return input === "just now" ? input : input + " ago";
        },
        s: "just now",
        future: "in %s",
        m: "1m",
        mm: "%dm",
        h: "1h",
        hh: "%dh",
        d: "1d",
        dd: "%dd",
        M: "1 month",
        MM: "%d months",
        y: "1 year",
        yy: "%d years",
      },
    });
  }

  render() {
    let date = moment(this.props.item.date).fromNow();
    let author = this.props.item.author;
    let stackLink =
      "/~srrs/" + this.props.item.author + "/" + this.props.item.stackName;
    let itemLink = stackLink + "/" + this.props.item.itemName
    const loc = {
      pathname: itemLink,
      state: { mode: "review",
              prevPath: location.pathname }
    }
    return (
      <div className="f9 lh-solid ml3">
        <div className="flex-col">
          <div className="mv6">
            <Link to={loc}>
              <TitleSnippet title={this.props.item.itemTitle} />
            </Link>
            <div className="flex">
              <div className="gray2 mr3">{author}</div>
              <div className="gray2 mr2">{date}</div>
             <Link to={stackLink} >
              <div className="gray2 mr2">{this.props.item.stackTitle}</div>
             </Link>

            </div>
          </div>
        </div>
      </div>
    );
  }
}
