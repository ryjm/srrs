import React, { Component } from 'react';
import { ItemPreview } from '../lib/item-preview';

export class StackNotes extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const items = this.props.items.map((item, key) => {
      return (
        <ItemPreview item={item} key={key} />
      );
    });

    return (
      <div className="flex flex-wrap" >
        {items}
      </div>
    );
  }
}
