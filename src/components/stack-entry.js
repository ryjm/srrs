import React, { Component } from 'react';
import { Route, Link } from 'react-router-dom';
import { HoverBox } from '~/components/HoverBox';
import { Box } from '@tlon/indigo-react';

export class StackEntry extends Component {
  render() {
    let { props } = this;
    const first = (props.index === 0) ? 'pt1' : 'pt6';

    return (
      <Link
        to={"/~srrs/" + props.path}>
        <HoverBox
          bg="white"
          bgActive="washedGray"
          selected={props.selected}
          width="100%"
          fontSize={0}
          px={3}
          py={1}
          display="flex"
          justifyContent="space-between"
          alignItems="center"
        >
          <Box py='1' pr='1'>{props.title}</Box>
        </HoverBox>
      </Link>
    );
  }
}

export default StackEntry
