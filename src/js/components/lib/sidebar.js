import React, { Component } from 'react';
import { Route, Link } from 'react-router-dom';
import { StackEntry } from '/components/stack-entry';

export class Sidebar extends Component {
  render() {
    const { props, state } = this;
    const activeClasses = (props.active === 'sidebar') ? ' ' : 'dn-s ';
    let hiddenClasses = true;
    if (props.popout) {
      hiddenClasses = false;
    } else {
      hiddenClasses = Boolean(!props.sidebarShown);
    };

    const stacks = {};
    Object.keys(props.pubs).map((stack) => {
        const title = `${stack}`;
        stacks[title] = props.pubs[stack];
      });
    Object.keys(props.subs).map((host) => {
    Object.keys(props.subs[host]).map((stack) => {
        const title = `~${host}/${stack}`;
        stacks[title] = props.subs[host][stack];
      });
    });

    const groupedStacks = {};
    Object.keys(stacks).map((stack) => {
      const owner = stacks[stack].info.owner;
      if (owner.slice(1) === window.ship) {
        if (groupedStacks['/~/']) {
          const array = groupedStacks['/~/'];
          array.push(stack);
          groupedStacks['/~/'] = array;
        } else {
          groupedStacks['/~/'] = [stack];
        };
      } else if (groupedStacks[owner]) {
        const array = groupedStacks[owner];
        array.push(stack);
        groupedStacks[owner] = array;
      } else {
        groupedStacks[owner] = [stack];
      }
    });

    let groupedItems = [];
    const groupedSubs = [];

    if (groupedStacks['/~/']) {
      groupedItems = groupedStacks['/~/']
        .map((stack) => {
          const owner = stacks[stack].info.owner;
          const path = `${owner}/${stacks[stack].info.filename}`;

          const selected = props.path === path;
          return (
            <StackEntry
              key={groupedStacks['/~/'].indexOf(stack)}
              title={stacks[stack].info.title}
              path={path}
              selected={selected}
            />
          );
        });
    }

    Object.keys(groupedStacks).forEach((host, i, arr) => {
      if (host === '/~/' || host.slice(1) === window.ship) {
        return null;
      }
      groupedSubs.push(groupedStacks[host].map((stack, i, arr) => {
          const owner = stacks[stack].info.owner;
          const path = `${owner}/${stacks[stack].info.filename}`;

          const selected = props.path === path;
          return (
            <StackEntry
              key={i}
              title={stacks[stack].info.title}
              path={path}
              selected={selected}
            />
          );
      }
                                 ));
    });

    return (
      <div
        className={
          'bn br-m br-l br-xl b--gray4 b--gray1-d lh-copy h-100 ' +
          'flex-shrink-0 pt3 pt0-m pt0-l pt0-xl relative ' +
          'overflow-y-hidden ' + activeClasses +
          (hiddenClasses ? 'flex-basis-100-s' : 'dn')
        }
      >
        <div className="w-100 f9">
          <Link to="/~srrs/review" className="blue2 pa4 f9 dib">
            Review
          </Link>
        </div>
        <div className="w-100 f9">
          <Link to="/~srrs/new-stack" className="green2 pa4 f9 dib">
            New Stack
          </Link>
        </div>
        <div className="overflow-y-auto pb1"
             style={{ height: 'calc(100% - 82px)' }}
        >
          <div className="w-100 f9 gray2 pa4 f9 dib">your stacks</div>
          {groupedItems}
          <div className="w-100 f9 gray2 pa4 f9 dib">subscriptions</div>
          {groupedSubs}
        </div>
      </div>
    );
  }
}

export default Sidebar;
