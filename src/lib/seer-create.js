import React, { Component } from 'react';
import { Link } from 'react-router-dom';

export class SrrsCreate extends Component {
  constructor(props) {
    super(props);
  }

  render () {
    if (!this.props.create) {
      return (
        <div className="flex">
        </div>
      );
    } else if (this.props.create == 'stack') {
      const link = {
        pathname: '/seer/new-stack',
        state: {
          lastPath: this.props.location.pathname,
          lastMatch: this.props.match.path,
          lastParams: this.props.match.params
        }
      };
      return (
        <div className="flex">
          <Link to={link}>
            <p className="bg-light-green green2 StackButton">new stack</p>
          </Link>
        </div>
      );
    } else if (this.props.create == 'item') {
      const link = {
        pathname: '/seer/new-item',
        state: {
          lastPath: this.props.location.pathname,
          lastMatch: this.props.match.path,
          lastParams: this.props.match.params
        }
      };
      return (
        <div className="flex">
          <Link to={link}>
            <p className="bg-light-green green2 StackButton">new item</p>
          </Link>
        </div>
      );
    }
  }
}
