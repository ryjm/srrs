import React, { Component } from 'react';
import { api } from '../../../api';

export class SidebarSwitcher extends Component {
  render() {

    let popoutSwitcher = this.props.popout
      ? "dn-m dn-l dn-xl"
      : "dib-m dib-l dib-xl";

    return (
      <div className={"absolute left-1 top-1 " + popoutSwitcher}>
        <a
          className="pointer flex-shrink-0"
          onClick={() => {
            api.sidebarToggle();
          }}>
          <img
            className={`pr3 dn ` + popoutSwitcher}
            src={
              this.props.sidebarShown
                ? "/~srrs/img/SwitcherOpen.png"
                : "/~srrs/img/SwitcherClosed.png"
            }
            height="16"
            width="16"
          />
        </a>
      </div>
    );
  }
}

export default SidebarSwitcher
