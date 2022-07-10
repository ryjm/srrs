import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import moment from 'moment';
import momentConfig from '../config/moment';

export class Pubs extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale('en', momentConfig);
  }

  buildStackData() {
    const data = Object.keys(this.props.pubs).map((stackId) => {
      const stack = this.props.pubs[stackId];
      return {
        url: `/seer/${stack.info.owner}/${stackId}`,
        title: stack.info.title,
        host: stack.info.owner,
        lastUpdated: moment(stack['last-update']).fromNow()
      };
    });
    return data;
  }

  render() {
    const stackData = this.buildStackData();

    const stacks = stackData.map( (data, i) => {
      const bg = (i % 2 == 0)
        ?  'bg-v-light-gray'
        :  'bg-white';
      const cls = 'w-100 flex ' + bg;
      return (
        <div className={cls} key={i}>
          <div className="fl body-regular-400 mw-336 w-336 pr3">
            <Link to={data.url}>
              <p className="ml3 mw-336">
                <span>{data.title}</span>
              </p>
            </Link>
          </div>
          <p className="fl body-regular-400" style={{ flexBasis: 336 }}>
            {data.host}
          </p>
          <p className="fl body-regular-400" style={{ flexBasis: 336 }}>
            {data.lastUpdated}
          </p>
        </div>
      );
    });

    return (
      <div>
          <div className="flex-column">
            <div className="flex">
              <p className="fl gray-50 body-regular-400" style={{ flexBasis: 336 }}>
                <span className="ml3">Title</span>
              </p>
              <p className="fl gray-50 body-regular-400" style={{ flexBasis: 336 }}>
                Host
              </p>
              <p className="fl gray-50 body-regular-400" style={{ flexBasis: 336 }}>
                Last Updated
              </p>
            </div>
            {stacks}
          </div>
      </div>
    );
  }
}
