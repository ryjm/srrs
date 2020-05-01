import React, { Component } from 'react';
import classnames from 'classnames';
import { NavLink } from 'react-router-dom';
import { SrrsCreate } from '/components/lib/srrs-create';
import { withRouter } from 'react-router';

const PC = withRouter(SrrsCreate);

export class HeaderMenu extends Component {
  render () {
    let reviewText = <p className="label-regular">Review</p>;
    let subsText = <p className="label-regular">Subscriptions</p>;

    return (
      <div className="fixed w-100 bg-white cf h-srrs-header z-4"
        style={{top:48}}>
        <PC create={"stack"}/>
        <div className="w-100 flex">
          <div className="fl bb b-gray-30 w-16" >
          </div>

          <NavLink exact
            className="header-menu-item"
            to="/~srrs/review"
            activeStyle={{
              color: "black",
              borderColor: "black",
            }}
            style={{flexBasis:148}}>
            Review
          </NavLink>

          <div className="fl bb b-gray-30 w-16" >
          </div>

          <NavLink exact
            className="header-menu-item"
            to="/~srrs/subs"
            activeStyle={{
              color: "black",
              borderColor: "black",
            }}
            style={{flexBasis:148}}>
            {subsText}
          </NavLink>

          <div className="fl bb b-gray-30 w-16" >
          </div>

          <NavLink exact
            className="header-menu-item"
            to="/~srrs/pubs"
            activeStyle={{
              color: "black",
              borderColor: "black",
            }}
            style={{flexBasis:148}}>
            Stacks
          </NavLink>

          <div className="fl bb b-gray-30 w-16" style={{flexGrow:1}}>
          </div>
        </div>
      </div>
    );
  }
}
