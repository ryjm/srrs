import React, { Component } from 'react';
import classnames from 'classnames';
import { ItemPreview } from '/components/lib/item-preview';
import { Link } from 'react-router-dom';

export class StackNotes extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (!this.props.items ||
        ((this.props.items.length === 0) &&
         (this.props.ship === window.ship))) {
      let link = {
        pathname: "/~srrs/new-item",
        state: {
          lastPath: this.props.location.pathname,
          lastMatch: this.props.match.path,
          lastParams: this.props.match.params,
        }
      }

      return (
        <div className="flex flex-wrap">
          <div className="w-336 relative">
            <hr className="gray-10" style={{marginTop: 48, marginBottom:25}}/>
            <Link to={link}>
              <p className="body-large b">
                -> Create First item
              </p>
            </Link>
          </div>
        </div>
      );
    }

    let items = this.props.items.map((item, key) => {
      return (
        <ItemPreview item={item} key={key}/>
      );
    });

    return (
      <div className="flex flex-wrap" style={{marginTop: 48}}>
        {items}
      </div>
    );
  }
}
