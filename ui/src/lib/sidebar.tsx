import React, { Component } from "react";
import { Route, Link } from "react-router-dom";
import Import from "../components/import";

import { StackEntry } from "../components/stack-entry";
import { Col, Row as R } from "@tlon/indigo-react";
import { isMobileCheck } from "./util";
import {
  Add,
  LibraryBooks,
  LocalLibrary,
  SelfImprovement,
} from "@mui/icons-material";
import { Accordion, AccordionSummary, Tooltip } from "@mui/material";
import { Box, Badge, Button, Stack } from "@mui/joy";

export class Sidebar extends Component {
  constructor(props, state) {
    super(props);
    this.hideStacks = this.hideStacks.bind(this);
    this.state = {
      ...state,
      hidden: false,
    };
  }
  hideStacks() {
    this.setState({ hidden: this.state.hidden ? false : true });
    this.setState({ redirect: "review" });
  }

  componentDidUpdate(prevProps, prevState) {
    const ship = this.props.ship;
    console.log("update");
    console.log("state: ", this.state);
    console.log("props: ", this.props);
  }
  render() {
    const { props, state } = this;

    const display = props.hidden ? "none" : "block";
    const stacks = {};
    Object.keys(props.pubs).map((stack) => {
      const title = `${stack}`;
      stacks[title] = props.pubs[stack];
    });
    Object.keys(props.subs).map((host) => {
      Object.keys(props.subs[host]).map((stack) => {
        const title = `~${host}/${stack}`;
        stacks[title] = props.subs[host][stack];
      });
    });

    const groupedStacks = {};
    Object.keys(stacks).map((stack) => {
      const owner = stacks[stack].info.owner;
      if (owner.slice(1) === window.ship) {
        if (groupedStacks["/~/"]) {
          const array = groupedStacks["/~/"];
          array.push(stack);
          groupedStacks["/~/"] = array;
        } else {
          groupedStacks["/~/"] = [stack];
        }
      } else if (groupedStacks[owner]) {
        const array = groupedStacks[owner];
        array.push(stack);
        groupedStacks[owner] = array;
      } else {
        groupedStacks[owner] = [stack];
      }
    });

    let groupedItems = [];
    const groupedSubs = [];

    if (groupedStacks["/~/"]) {
      groupedItems = groupedStacks["/~/"].map((stack) => {
        const owner = stacks[stack].info.owner;
        const path = `${owner}/${stacks[stack].info.filename}`;

        const selected = props.path === path;
        return (
          <StackEntry
            key={groupedStacks["/~/"].indexOf(stack)}
            title={stacks[stack].info.title}
            path={path}
            selected={selected}
          />
        );
      });
    }
    Object.keys(groupedStacks).forEach((host, i, arr) => {
      if (host === "/~/" || host.slice(1) === window.ship) {
        return null;
      }
      groupedSubs.push(
        groupedStacks[host].map((stack, i, arr) => {
          const owner = stacks[stack].info.owner;
          const path = `${owner}/${stacks[stack].info.filename}`;

          const selected = props.path === path;
          return (
            <StackEntry
              key={i}
              title={stacks[stack].info.title}
              path={path}
              selected={selected}
            />
          );
        })
      );
    });
    const isMobile = isMobileCheck();
    return (
      <Col
        borderRight={[0, 1]}
        style={{
          flexBasis: "auto",
          flexDirection: isMobile ? "column-reverse" : "row",
        }}
        borderRightColor={["washedGray", "washedGray"]}
        borderBottom={isMobile ? "1px solid lightgray" : undefined}
        height={isMobile ? "auto" : "100%"}
        display={display}
        minWidth={150}
        maxWidth={250}
      >
        <Box sx={{ flexDirection: isMobile ? "column-reverse" : "column" }}>
          <Stack sx={{ pt: 2, p: 2, pl: .5 }} spacing={1} direction={"row"}>
            <Link to="/seer/new-stack">
              <Tooltip arrow placement="top-start" title="New Stack">
                <Button size="lg">
                  <Add />
                </Button>
              </Tooltip>
            </Link>
            <Link to="/seer/review">
              <Tooltip placement="top-start" arrow title="Review">
              <Badge
                    color="success"
                    anchorOrigin={{ vertical: "top", horizontal: "right" }}
                    badgeContent={props.review.length}
                  >
                  
                <Button size="lg">
                <SelfImprovement />
                    
                    
                </Button>
                </Badge>
              </Tooltip>
            </Link>
          </Stack>
          <Accordion>
            <AccordionSummary>
              <LibraryBooks /> Library
            </AccordionSummary>
            {groupedItems}
          </Accordion>
          <Accordion>
            <AccordionSummary>
              <LocalLibrary /> Borrowed
            </AccordionSummary>
            {groupedSubs}
          </Accordion>
        </Box>
      </Col>
    );
  }
}

export default Sidebar;
