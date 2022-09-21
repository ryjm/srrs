import React, { Component } from "react";
import moment from "moment";
import { Link } from "react-router-dom";
import { ItemSnippet } from "./item-snippet";
import { TitleSnippet } from "./title-snippet";
import momentConfig from "../config/moment";
import { Typography, Box, Button, Stack } from "@mui/joy";

export class ItemPreview extends Component {
  constructor(props) {
    super(props);

    moment.updateLocale("en", momentConfig);
    this.saveGrade = this.saveGrade.bind(this);
  }

  saveGrade() {
    this.props.setSpinner(true);
    const data = {
      "answered-item": {
        stak: this.props.stackId,
        item: this.props.itemId,
        answer: this.state.recallGrade,
      },
    };
    this.setState(
      {
        awaitingGrade: {
          ship: this.state.ship,
          stackId: this.props.stackId,
          itemId: this.props.itemId,
        },
      },
      () => {
        this.props.api.action("seer", "seer-action", data);
      }
    );
  }
  render() {
    const lastReview =
      this.props.item.lastReview === null
        ? "never"
        : moment(this.props.item.lastReview).fromNow();
    const date = moment(this.props.item.date).fromNow();

    const stackLink =
      "/seer/" + this.props.item.stackOwner + "/" + this.props.item.stackName;
    const itemLink = stackLink + "/" + this.props.item.itemName;

    return (
      <Link to={{ pathname: itemLink, state: { prevPath: location.pathname } }}>
        <Button
          variant="outlined"
          color="success"
          sx={{
            letterSpacing: ".1rem",
            borderRadius: "sm",
          }}
        >
          <Stack spacing={1}>
          <TitleSnippet title={this.props.item.itemTitle} />
          <ItemSnippet body={this.props.item.itemSnippet} />
          <Typography
            mb={1}
            variant="outlined"
            textColor="text.tertiary"
            component="p"
          >
            {" "}
            {lastReview}
          </Typography>
          <Typography
            level="body3"
            variant="outlined"
            textColor="text.tertiary"
            component="p"
          >
            {" "}
            {date}
          </Typography>
          </Stack>
        </Button>
      </Link>
    );
  }
}
