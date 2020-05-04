import { HeaderBar } from '/components/lib/header-bar';
import { HeaderMenu } from '/components/lib/header-menu';
import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { SrrsCreate } from '/components/lib/srrs-create';
import { Sidebar } from '/components/lib/sidebar';
import { withRouter } from 'react-router';

const PC = withRouter(SrrsCreate);
const HM = withRouter(HeaderMenu);

export class Skeleton extends Component {
  render() {
    const { props, state } = this;

    /* let rightPanelHide = props.rightPanelHide
      ? "dn-s" : "";
 */
    let rightPanelHide = true
    let popout = !!props.popout
      ? props.popout : false;

    let popoutWindow = (popout)
      ? "" : "h-100-m-40-ns ph4-m ph4-l ph4-xl pb4-m pb4-l pb4-xl"

    let popoutBorder = (popout)
      ? "" : "ba-m ba-l ba-xl b--gray4 b--gray1-d br1"

    let reviewText = <p className="label-regular">Review</p>;
    let subsText = <p className="label-regular">Subscriptions</p>;
    let tabStyles = {
      review: "bb b--gray4 b--gray2-d gray2 pv4 ph2",
      stacks: "bb b--gray4 b--gray2-d gray2 pv4 ph2",
      settings: "bb b--gray4 b--gray2-d pr2 gray2 pv4 ph2",
    };
    return (
      <div className={"absolute h-100 w-100 " + popoutWindow}>
        <HeaderBar spinner={this.props.spinner} />
        <div className={`cf w-100 flex ` + popoutBorder}>
              <Sidebar
                popout={popout}
                pubs={this.props.pubs}
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

