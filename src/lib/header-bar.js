import React, { Component } from 'react';
import { cite } from '~/lib/util';
import { IconHome } from '~/lib/icons/icon-home';
import { Sigil } from '~/lib/icons/sigil';

export class HeaderBar extends Component {
  render() {
    const title = document.title === 'home' ? '' : 'seer';

    return (
      <div
        className={
          'bg-white bg-gray0-d w-100 justify-between relative tc pt3 db'
        }
        style={{ height: 40 }}
      >
        <a
          className="dib gray2 f9 inter absolute left-0"
          href="/"
          style={{ top: 14 }}
        >
          <IconHome />
          <span
            className="ml2 white-d v-top lh-title"
            style={{ paddingTop: 3 }}
          >
            home
          </span>
        </a>
        <span
          className="f9 white-d inter dib"
          style={{
            verticalAlign: 'text-top',
            paddingTop: 3
          }}
        >
          {title}
        </span>
        <div className="absolute right-0 lh-copy" style={{ top: 8 }}>
          <Sigil
            ship={'~' + window.ship}
            classes="v-mid mix-blend-diff"
            size={16}
            color={'#000000'}
          />
          <span className="mono white-d f9 ml2 c-default">{cite(window.ship)}</span>
        </div>
      </div>
    );
  }
}
