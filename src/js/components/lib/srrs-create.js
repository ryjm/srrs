import React, { Component } from 'react';
import classnames from 'classnames';
import { Link } from 'react-router-dom';
import { withRouter } from 'react-router';

export class SrrsCreate extends Component {
  constructor(props){
    super(props);
  }

  render () {
    if (!this.props.create) {
      return (
        <div className="flex">
        </div>
      );
    } else if (this.props.create == 'stack') {
      let link = {
        pathname: "/~srrs/new-stack",
        state: {
          lastPath: this.props.location.pathname,
          lastMatch: this.props.match.path,
          lastParams: this.props.match.params,
        },
      };
      return (
        <div className="flex">
          <Link to={link}>
            <p className="bg-light-green green2 StackButton">New Stack</p>
          </Link>
        </div>
      );
    } else if (this.props.create == 'item') {
      let link = {
        pathname: "/~srrs/new-item",
        state: {
          lastPath: this.props.location.pathname,
          lastMatch: this.props.match.path,
          lastParams: this.props.match.params,
        },
      };
      return (
        <div className="flex">
          <Link to={link}>
            <p className="bg-light-green green2 StackButton">New Item</p>
          </Link>
        </div>
      );
    }
  }
}
