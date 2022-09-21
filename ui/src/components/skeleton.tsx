import React, { Component } from 'react';

import HeaderBar from '../lib/header-bar';
import { Sidebar } from '../lib/sidebar';
import { isMobileCheck } from '../lib/util';


  
  function Skeleton(props) {
    
    let rightPanelHide = true;
    let popout = !!props.popout ? props.popout : false;

    let popoutWindow = popout
      ? ""
      : "h-100-m-40-ns ph4-m ph4-l ph4-xl pb4-m pb4-l pb4-xl";

    let popoutBorder = popout ? "" : "ba-m ba-l ba-xl b--gray4 b--gray1-d br1";

    return (
      <div className={"absolute h-100 w-100 " + popoutWindow}>
        
        <HeaderBar open={false} api={props.api} spinner={props.spinner} />
        <div
          className={`cf w-100 h-100 flex ` + popoutBorder}
          style={{
            flexDirection: isMobileCheck() ? "column-reverse" : "row",
          }}
        >
          <Sidebar
            hidden={false}
            popout={popout}
            pubs={props.pubs}
            subs={props.subs}
            path={props.path}
            api={props.api}
            review={props.review}
          />
          <div
            className={"h-100 w-100 white-d flex relative " + rightPanelHide}
            style={{
              flexGrow: 1,
            }}
          >
            {props.children}
          </div>
        </div>
      </div>
    );
  }
export default Skeleton;
