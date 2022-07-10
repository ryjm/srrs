import React, { Component } from 'react';
import { Route, Link } from 'react-router-dom';
import { StackEntry } from '../components/stack-entry';
import { Col, Box, Row } from '@tlon/indigo-react';
import { isMobileCheck } from './util';
export class Sidebar extends Component {
  constructor(props) {
    super(props);
    this.hideStacks = this.hideStacks.bind(this);
    this.state = { hidden: false };
  }
  hideStacks() {
    this.setState({ hidden: this.state.hidden ? false : true });
    this.setState({ redirect: 'review' });
  }
  render() {
    const { props, state } = this;

    const display = props.hidden ? 'none' : 'block';
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
    const isMobile = isMobileCheck()
    return (
      <Col
        borderRight={[0, 1]}
        style={{ flexDirection: isMobile ? 'column' : 'row' }}
        borderRightColor={["washedGray", "washedGray"]}
        borderBottom={isMobile ? '1px solid lightgray' : undefined}
        height={isMobile ? "20%" : "100%"}
        pt={[3, 0]}
        display={display}
        width={["auto"]}
      >
        <Box height='100%' style={{ flexDirection: isMobile ? 'column' : 'column' }} className='flex'>
          <Box>
            <Link to="/seer/review" className="shadow-hover ba flex blue2 pv1 ph1 f9 dib">
              review
            </Link>
            <Link to="/seer/new-stack" className="shadow-hover ba flex green2 ph1 pv1 f9 dib">
              new stack
            </Link>
          </Box>
          <Box overflow='auto'>
            <div onClick={this.hideStacks} className="w-100 f9 gray2 pa4 f9 dib shadow-hover ba">your stacks</div>
            <Box height='50%' overflow='auto' className="flex-auto" display={this.state.hidden ? 'none' : 'block'} >
              {groupedItems}
            </Box>
            <Box overflow='auto'> 
            <div className="w-100 f9 gray2 pa4 f9 dib">subscriptions</div>
            {groupedSubs}
            </Box>
          </Box>
        </Box>
      </Col>
    );
  }
}

export default Sidebar;