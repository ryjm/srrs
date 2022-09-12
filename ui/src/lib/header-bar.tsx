import { AlarmTwoTone } from '@mui/icons-material';
import { AppBar, ButtonGroup, Fade, IconButton, LinearProgress, Toolbar } from '@mui/material';
import { usePopupState } from 'material-ui-popup-state/hooks';
import React, { Component, useEffect } from 'react';
import { Link } from 'react-router-dom';
import Import from '~/components/import';

const HeaderBar = (props) => {
  const title = document.title === "home" ? "" : "%srrs";

  return (
    <AppBar position="static" color="transparent">
      <Toolbar>
        <IconButton size="large" edge="start" color="inherit" sx={{ mr: 2 }}>
          <Link className="mono green-text" to="/seer/review">
            <AlarmTwoTone /> {title}
          </Link>
        </IconButton>
        <ButtonGroup>
          <Import api={props.api}></Import>
        </ButtonGroup>
      </Toolbar>
      <Fade
     in={props.spinner}
     style={{
       transitionDelay: props.spinner ? '0ms' : '0ms',
     }}
     unmountOnExit
   >
     <LinearProgress />
   </Fade>
    
    </AppBar>

  );
};
export default HeaderBar;
("");
