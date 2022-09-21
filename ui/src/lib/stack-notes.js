import { Box, Grid } from '@mui/joy';
import React, { Component } from 'react';
import { ItemPreview } from '../lib/item-preview';

export class StackNotes extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const items = this.props.items.map((item, key) => {
      return (
        <Grid pt={2} item>
        <ItemPreview item={item} key={key} />
        </Grid>
      );
    });

    return items;
  }
}
