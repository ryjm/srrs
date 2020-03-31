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
        <div className="w-100">
          <p className="srrs">Srrs</p>
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
        <div className="w-100">
          <p className="srrs">Srrs</p>
          <Link to={link}>
            <p className="create">+New Stack</p>
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
        <div className="w-100">
          <p className="srrs">Srrs</p>
          <Link to={link}>
            <p className="create">+New Item</p>
          </Link>
        </div>
      );
    }
  }
}
