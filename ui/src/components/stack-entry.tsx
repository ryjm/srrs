import { AccordionDetails } from "@mui/material";
import React, { Component } from "react";
import { Link } from "react-router-dom";

export class StackEntry extends Component {
  render() {
    let { props } = this;

    return (
      <AccordionDetails>
        <Link to={"/seer/" + props.path}>{props.title}</Link>
      </AccordionDetails>
    );
  }
}

export default StackEntry;
