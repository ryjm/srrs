import React from 'react';
import { Link } from 'react-router-dom';
import styled from 'styled-components';
import { Box } from '@tlon/indigo-react';
interface HoverBoxProps {
  selected: boolean;
  bg: string;
  bgActive: string;
}
export const HoverBox = styled(Box)<HoverBoxProps>`
  background-color: ${p =>
    p.selected ? p.theme.colors[p.bgActive] : p.theme.colors[p.bg]};
  pointer: cursor;
  &:hover {
    background-color: ${p => p.theme.colors[p.bgActive]};
  }
`;

export const HoverBoxLink = ({ to, children, theme }) => (
  <Link to={to}>
    <HoverBox {...theme}>{children}</HoverBox>
  </Link>
);
