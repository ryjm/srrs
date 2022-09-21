import { Button, Typography } from "@mui/joy";
import { AccordionDetails } from "@mui/material";
import React, { Component } from "react";
import { Link } from "react-router-dom";

export class StackEntry extends Component {
  render() {
    let { props } = this;

    return (
      <AccordionDetails>
        <Link to={"/seer/" + props.path}>
          <Button variant="soft" color="neutral">
            <Typography
              textColor="neutral.500"
              fontWeight={700}
              sx={{
                fontSize: "10px",
                textTransform: "uppercase",
                letterSpacing: ".1rem",
              }}
            >
              {props.title}
            </Typography>
          </Button>
        </Link>
      </AccordionDetails>
    );
  }
}

export default StackEntry;
