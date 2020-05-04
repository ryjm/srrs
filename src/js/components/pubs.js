import React, { Component } from 'react';
import classnames from 'classnames';
import { Link } from 'react-router-dom'
import { withRouter } from 'react-router';
import { HeaderMenu } from '/components/lib/header-menu';
import moment from 'moment';

const HM = withRouter(HeaderMenu);

export class Pubs extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale('en', {
      relativeTime: {
        past: function(input) {
          return input === 'just now'
            ? input
            : input + ' ago'
        },
        s : 'just now',
        future : 'in %s',
        m  : '1m',
        mm : '%dm',
        h  : '1h',
        hh : '%dh',
        d  : '1d',
        dd : '%dd',
        M  : '1 month',
        MM : '%d months',
        y  : '1 year',
        yy : '%d years',
      }
    });
  }

  buildStackData() {
    let data = Object.keys(this.props.pubs).map((stackId) => {
      let stack = this.props.pubs[stackId];
      return {
        url: `/~srrs/${stack.info.owner}/${stackId}`,
        title: stack.info.title,
        host: stack.info.owner,
        lastUpdated: moment(stack["last-update"]).fromNow(),
      }
    });
    return data;
  }


  render() {
    let stackData = this.buildStackData();

    let stacks = this.buildStackData().map( (data, i) => {
      let bg = (i % 2 == 0)
        ?  "bg-v-light-gray"
        :  "bg-white";
      let cls = "w-100 flex " + bg;
      return (
        <div className={cls} key={i}>
          <div className="fl body-regular-400 mw-336 w-336 pr3">
            <Link to={data.url}>
              <p className="ml3 mw-336">
                <span>{data.title}</span>
              </p>
            </Link>
          </div>
          <p className="fl body-regular-400" style={{flexBasis:336}}>
            {data.host}
          </p>
          <p className="fl body-regular-400" style={{flexBasis:336}}>
            {data.lastUpdated}
          </p>
        </div>
      );
    });


    return (
      <div>
          <div className="flex-column">
            <div className="flex">
              <p className="fl gray-50 body-regular-400" style={{flexBasis:336}}>
                <span className="ml3">Title</span>
              </p>
              <p className="fl gray-50 body-regular-400" style={{flexBasis:336}}>
                Host
              </p>
              <p className="fl gray-50 body-regular-400" style={{flexBasis:336}}>
                Last Updated
              </p>
            </div>
            {stacks}
          </div>
      </div>
    );
  }
}
