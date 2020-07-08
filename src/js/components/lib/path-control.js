import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { withRouter } from 'react-router';
import { SrrsCreate } from '/components/lib/srrs-create';

const PC = withRouter(SrrsCreate);

export class PathControl extends Component {
  constructor(props) {
    super(props);
  }

  buildPathData() {
    const path = [
      { text: 'Home', url: '/~srrs/review' }
    ];

    const last = this.props.location.state || false;
    const ship = last.lastParams.ship.slice(1);
    const stackId = last.lastParams.stack;
    let stack = false;
    let finalUrl = this.props.location.pathname;

    if (last) {
      finalUrl = {
        pathName: finalUrl,
        state: last
      };

      if ((last.lastMatch === '/~srrs/:ship/:stack/:item') ||
          (last.lastMatch === '/~srrs/:ship/:stack')) {
        stack = (ship == window.ship)
          ? this.props.pub[stackId] || false
          : this.props.subs[ship][stackId] || false;
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
          url: `/~srrs/${stack.info.owner}/${stack.info.filename}`
        });
      }
      path.push(
        { text: 'New Note', url: finalUrl }
      );
    }
    return path;
  }

  render() {
    const pathData = (this.props.pathData)
      ?  this.props.pathData
      :  this.buildPathData();
    const path = [];
    let key = 0;

    pathData.forEach((seg, i) => {
      const style = (i == 0)
        ?  { marginLeft: 16 }
        :  {};
      if (i === pathData.length - 1)
        style.color = 'black';

      path.push(
        <Link to={seg.url} key={key++}
          className="fl gray-30 label-regular one-line mw-336" style={style}
        >
          {seg.text}
        </Link>
      );
      if (i < (pathData.length - 1)) {
        path.push(
          <img src="/~srrs/arrow.png"
          className="fl ml1 mr1 relative"
          style={{ top: 5 }}
          key={key++}
          />
        );
      }
    });

    const create = ((window.location.pathname === '/~srrs/new-stack') ||
      (window.location.pathname === '/~srrs/new-item')) ||
      (this.props.create === false)
      ?  false
      :  'item';

    return (
      <div>
        <PC create={create} />
      </div>
    );
  }
}
