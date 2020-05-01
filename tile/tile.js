import React, { Component } from 'react';
import classnames from 'classnames';
import _ from 'lodash';


export default class SrrsTile extends Component {
  constructor(props){
    super(props);
  }

  render(){
    let info = [];
    if (this.props.data.review > 0) {
      let text = (this.props.data.review == 1)
        ?  "Review"
        :  "Reviews"
      info.push(
        <p key={1}>
          <span className="green-medium">{this.props.data.review} </span>
          <span>{text}</span>
        </p>
      );
    }

    return (
      <div className={"w-100 h-100 relative bg-white bg-gray0-d ba " +
        "b--black b--gray1-d"}>
        <a className="w-100 h-100 db pa2 no-underline" href="/~srrs">
          <p className="black white-d absolute f9" style={{ left: 8, top: 8 }}>srrs</p>
        </a>
        <div className="absolute w-100 flex-col body-regular black"
          style={{ verticalAlign: "bottom", bottom: 8, left: 8 }}>
          {info}
        </div>
      </div>

    );
  }

}

window.srrsTile = SrrsTile;
