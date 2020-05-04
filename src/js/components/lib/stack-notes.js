import React, { Component } from 'react';
import classnames from 'classnames';
import { ItemPreview } from '/components/lib/item-preview';
import { Link } from 'react-router-dom';

export class StackNotes extends Component {
  constructor(props) {
    super(props);
  }

  render() {

    let items = this.props.items.map((item, key) => {
      return (
        <ItemPreview item={item} key={key}/>
      );
    });

    return (
      <div className="flex-col" >
        {items}
      </div>
    );
  }
}
