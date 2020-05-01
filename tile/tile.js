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
      <div className="w-100 h-100 relative" style={{background: "white"}}>
        <a className="w-100 h-100 db no-underline" href="/~srrs">
          <p className="gray label-regular b absolute"
            style={{left: 8, top: 4}}>
            Srrs
          </p>
          <div className="absolute w-100 flex-col body-regular black"
            style={{verticalAlign: "bottom", bottom: 8, left: 8}}>
            {info}
          </div>
        </a>
      </div>
    );
  }

}

window.srrsTile = SrrsTile;
