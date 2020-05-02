import React, { Component } from 'react';
import classnames from 'classnames';
import { Link } from 'react-router-dom';
import { withRouter } from 'react-router';
import { SrrsCreate } from '/components/lib/srrs-create';
import _ from 'lodash';

const PC = withRouter(SrrsCreate);

export class PathControl extends Component {
  constructor(props){
    super(props);

  }

  buildPathData(){
    let path = [
      { text: "Home", url: "/~srrs/review" },
    ];

    let last = _.get(this.props, 'location.state', false);
    let stack = false;
    let finalUrl = this.props.location.pathname;

    if (last) {
      finalUrl = {
        pathName: finalUrl,
        state: last,
      };

      if ((last.lastMatch === '/~srrs/:ship/:stack/:item') ||
          (last.lastMatch === '/~srrs/:ship/:stack')){
        stack = (last.lastParams.ship.slice(1) == window.ship)
          ?  _.get(this.props, `pubs["${last.lastParams.stack}"]`, false)
          :  _.get(this.props,
            `subs["${last.lastParams.ship.slice(1)}"]["${last.lastParams.stack}"]`, false);
      }
    }

    if (this.props.location.pathname === '/~srrs/new-stack') {
      path.push(
        { text: 'New Stack', url: finalUrl }
      );
    } else if (this.props.location.pathname === '/~srrs/new-item') {
      if (stack) {
        path.push({
          text: stack.info.title,
          url: `/~srrs/${stack.info.owner}/${stack.info.filename}`,
        });
      }
      path.push(
        { text: 'New Note', url: finalUrl }
      );
    }
    return path;
  }

  render() {
    let pathData = (this.props.pathData)
      ?  this.props.pathData
      :  this.buildPathData();
    let path = [];
    let key = 0;

    pathData.forEach((seg, i) => {
      let style = (i == 0)
        ?  {marginLeft: 16}
        :  {};
      if (i === pathData.length - 1)
        style.color = "black";

      path.push(
        <Link to={seg.url} key={key++}
          className="fl gray-30 label-regular one-line mw-336" style={style}>
          {seg.text}
        </Link>
      );
      if (i < (pathData.length - 1)) {
        path.push(
          <img src="/~srrs/arrow.png"
          className="fl ml1 mr1 relative"
          style={{top: 5}}
          key={key++}/>
        );
      }
    });

    let create = ((window.location.pathname === '/~srrs/new-stack') ||
      (window.location.pathname === '/~srrs/new-item')) ||
      (this.props.create === false)
      ?  false
      :  'item';

    return (
      <div>
        <PC create={create}/>
      </div>
    );
  }
}
