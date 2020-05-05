import React, { Component } from 'react'
import { Route, Link } from 'react-router-dom';
import { StackEntry } from '/components/stack-entry';

export class Sidebar extends Component {
  render() {
    const { props, state } = this;
    let activeClasses = (props.active === "sidebar") ? " " : "dn-s ";
    let hiddenClasses = true;
    if (props.popout) {
      hiddenClasses = false;
    } else {
      hiddenClasses = !!!props.sidebarShown;
    };


    let stacks = {};
    Object.keys(props.pubs).map(host => {
      Object.keys(props.pubs).map(stack => {
        let title = `${stack}`;
        stacks[title] = props.pubs[stack];
      })
    });

    let groupedStacks = {};
    Object.keys(stacks).map(stack => {
      if (groupedStacks["/~/"]) {
        let array = groupedStacks["/~/"];
        array.push(stack);
        groupedStacks["/~/"] = array;
      } else {
        groupedStacks["/~/"] = [stack];
      };
    });

    let groupedItems = [];

    if (groupedStacks["/~/"]) {
      groupedItems = groupedStacks["/~/"]
        .map(stack => {
          let owner = stacks[stack].info.owner
          let path = `${owner}/${stacks[stack].info.filename}`

          let selected = props.path === path
          return (
            <StackEntry
              key={groupedStacks["/~/"].indexOf(stack)}
              title={stacks[stack].info.title}
              path={path}
              selected={selected}
            />
          )
        })
    }


    return (
      <div
        className={
          "bn br-m br-l br-xl b--gray4 b--gray1-d lh-copy h-100 " +
          "flex-shrink-0 pt3 pt0-m pt0-l pt0-xl relative " +
          "overflow-y-hidden " + activeClasses +
          (hiddenClasses ? "flex-basis-100-s flex-basis-250-ns" : "dn")
        }>
        <a className="db dn-m dn-l dn-xl f9 pb3 pl3" href="/">
          ⟵ Landscape
        </a>
        <div className="w-100 f9">
          <Link to="/~srrs/new-stack" className="green2 pa4 f9 dib">
            New Stack
          </Link>
        </div>
        <div className="overflow-y-auto pb1"
          style={{ height: "calc(100% - 82px)" }}>
          {groupedItems}
        </div>
      </div>
    );
  }
}

export default Sidebar;
