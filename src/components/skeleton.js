import { HeaderBar } from '~/lib/header-bar';
import { HeaderMenu } from '~/lib/header-menu';
import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { SrrsCreate } from '~/lib/seer-create';
import { Sidebar } from '~/lib/sidebar';
import { withRouter } from 'react-router';


export class Skeleton extends Component {
render() {

  const { props, state } = this;
    
    let rightPanelHide = true
    let popout = !!props.popout
      ? props.popout : false;

    let popoutWindow = (popout)
      ? "" : "h-100-m-40-ns ph4-m ph4-l ph4-xl pb4-m pb4-l pb4-xl"

    let popoutBorder = (popout)
      ? "" : "ba-m ba-l ba-xl b--gray4 b--gray1-d br1"

    return (
      <div className={"absolute h-100 w-100 " + popoutWindow}>
        <HeaderBar spinner={this.props.spinner} />
        <div className={`cf w-100 h-100 flex ` + popoutBorder}>
              <Sidebar
                popout={popout}
                pubs={this.props.pubs}
                subs={this.props.subs}
                path={this.props.path}
              />
              <div className={"h-100 w-100 relative white-d flex-auto " + rightPanelHide} style={{
                flexGrow: 1,
              }}>
                {props.children}
              </div>
            </div>
          </div>
    );
  }
}

