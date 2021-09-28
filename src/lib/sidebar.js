import React, { Component } from 'react';
import { Route, Link } from 'react-router-dom';
import { StackEntry } from '~/components/stack-entry';
import { Col, Box } from '@tlon/indigo-react';

export class Sidebar extends Component {
  render() {
    const { props, state } = this;
    const display = props.hidden ? ['none', 'block'] : 'block';
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
      <Col
        borderRight={[0, 1]}
        borderRightColor={["washedGray", "washedGray"]}
        height="100%"
        pt={[3, 0]}
        overflowY="auto"
        display={display}
        flexShrink={0}
        width={["auto", "250px"]}
      >
        <Box>
          <Link to="/seer/review" className="blue2 pa4 f9 dib">
            Review
          </Link>
          <Box>
            <Link to="/seer/new-stack" className="green2 pa4 f9 dib">
              New Stack
          </Link>
          </Box>
          <Box>
            <div className="w-100 f9 gray2 pa4 f9 dib">your stacks</div>
            {groupedItems}
            <div className="w-100 f9 gray2 pa4 f9 dib">subscriptions</div>
            {groupedSubs}
          </Box>
        </Box>
      </Col>
    );
  }
}

export default Sidebar;
