import React, { Component } from 'react';
import { IconInbox } from '~/lib/icons/icon-inbox';
import { IconComment } from '~/lib/icons/icon-comment';
import { IconSig } from '~/lib/icons/icon-sig';
import { IconDecline } from '~/lib/icons/icon-decline';
import { IconUser } from '~/lib/icons/icon-user';

export class Icon extends Component {
  render() {
    let iconElem = null;

    switch(this.props.type) {
      case 'icon-stream-chat':
        iconElem = <span className="icon-stream-chat"></span>;
        break;
      case 'icon-stream-dm':
        iconElem = <span className="icon-stream-dm"></span>;
        break;
      case 'icon-stack-index':
        iconElem = <span className="icon-stack"></span>;
        break;
      case 'icon-stack-item':
        iconElem = <span className="icon-stack-item"></span>;
        break;
      case 'icon-stack-comment':
        iconElem = <span className="icon-stack icon-stack-comment"></span>;
        break;
      case 'icon-panini':
        // TODO: Should icons be display: block, inline, or inline-blocks?
        //   1) Should naturally flow inline
        //   2) But can't make icon-panini naturally inline without hacks like &nbsp;
        iconElem = <div className="icon-panini"></div>;
        break;
      case 'icon-x':
        iconElem = <span className="icon-x"></span>;
        break;
      case 'icon-decline':
        iconElem = <IconDecline />;
        break;
      case 'icon-lus':
        iconElem = <span className="icon-lus"></span>;
        break;
      case 'icon-inbox':
        iconElem = <IconInbox />;
        break;
      case 'icon-comment':
        iconElem = <IconComment />;
        break;
      case 'icon-sig':
        iconElem = <IconSig />;
        break;
      case 'icon-user':
        iconElem = <IconUser />;
        break;
      case 'icon-ellipsis':
        iconElem = (
          <div className="icon-ellipsis-wrapper icon-label">
            <div className="icon-ellipsis-dot"></div>
            <div className="icon-ellipsis-dot"></div>
            <div className="icon-ellipsis-dot"></div>
          </div>
        );
        break;
    }

    const className = this.props.label ? 'icon-label' : '';

    return (
      <span className={className}>
        {iconElem}
      </span>
    );
  }
}
