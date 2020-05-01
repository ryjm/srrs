import React, { Component } from 'react';
import classnames from 'classnames';
import { Link } from 'react-router-dom';
import { withRouter } from 'react-router';
import { HeaderMenu } from '/components/lib/header-menu';
import moment from 'moment';

const HM = withRouter(HeaderMenu);

export class Subs extends Component {
  constructor(props) {
    super(props);

    this.accept = this.accept.bind(this);
    this.reject = this.reject.bind(this);
    this.unsubscribe = this.unsubscribe.bind(this);

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

    let data = Object.keys(this.props.subs).map((ship) => {
      let perShip = Object.keys(this.props.subs[ship]).map((stackId) => {
        let stack = this.props.subs[ship][stackId];
        return {
          type: 'regular',
          url: `/~srrs/${stack.info.owner}/${stackId}`,
          title: stack.info.title,
          host: stack.info.owner,
          lastUpdated: moment(stack["last-update"]).fromNow(),
          stackId: stackId,
        }
      });
      return perShip;
    });
    let merged = data.flat();
    return merged;
  }

  accept(host, stackId) {
    let subscribe = {
      subscribe: {
        who: host.slice(1),
        stack: stackId,
      }
    };
    this.props.api.action("srrs", "srrs-action", subscribe);
  }

  reject(host, stackId) {
    let reject = {
      "reject-invite": {
        who: host.slice(1),
        stack: stackId,
      }
    };
    this.props.api.action("srrs", "srrs-action", reject);
  }

  unsubscribe(host, stackId) {
    let unsubscribe = {
      unsubscribe: {
        who: host.slice(1),
        stack: stackId,
      }
    };
    this.props.api.action("srrs", "srrs-action", unsubscribe);
  }

  render() {
    let stackData = this.buildStackData();

    let stacks = this.buildStackData().map( (data, i) => {
      let bg = (i % 2 == 0)
        ?  "bg-v-light-gray"
        :  "bg-white";
      let cls = "w-100 flex " + bg;
      if (data.type === 'regular') {
        return (
          <div className={cls} key={i}>
            <div className="fl mw-336" style={{flexBasis: 336}}>
              <Link to={data.url}>
                <p className="body-regular-400 pr3 ml3">
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
            <p className="fl body-regular-400 pointer"
              style={{flexBasis:336}}
              onClick={this.unsubscribe.bind(this, data.host, data.stackId)}>
              Unsubscribe
            </p>
          </div>
        );
      }
    });

    return (
      <div>
        <HM />
        <div className="absolute w-100" style={{top:124}}>
          <div className="flex-column">
            <div className="w-100">
              <h2 className="gray-50"
                style={{marginLeft: 16, marginTop: 32, marginBottom: 16}}>
                Subscriptions
              </h2>
            </div>
            <div className="w-100 flex">
              <p className="fl gray-50 body-regular-400" style={{flexBasis:336}}>
                <span className="ml3">Title</span>
              </p>
              <p className="fl gray-50 body-regular-400" style={{flexBasis:336}}>
                Host
              </p>
              <p className="fl gray-50 body-regular-400" style={{flexBasis:336}}>
                Last Updated
              </p>
              <p className="fl gray-50 body-regular-400" style={{flexBasis:336}}>
              </p>
            </div>

            {stacks}
          </div>
        </div>
      </div>
    );
  }
}
