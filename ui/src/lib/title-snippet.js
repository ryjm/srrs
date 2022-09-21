import { Typography } from "@mui/joy";
import React, { Component } from "react";
import { color } from "styled-system";

export class TitleSnippet extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (this.props.badge) {
      return (
        <div
          className=""
          style={{ overflowWrap: "break-word", alignContent: "center" }}
        >
          {this.props.title}
        </div>
      );
    } else {
      return (
        <Typography textColor='text.primary' level="h6" textOverflow="ellipsis">
          {this.props.title}
        </Typography>
      );
    }
  }
}
