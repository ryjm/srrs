import React, { Component } from "react";
import { Link } from "react-router-dom";
import { dateToDa } from "../lib/util";
import CodeMirror from "@uiw/react-codemirror";

import { basicSetup } from "codemirror";
import { emacs } from "@replit/codemirror-emacs";
import { markdown, markdownLanguage } from "@codemirror/lang-markdown";
import { Box, Button, Grid, IconButton, Stack, Typography } from "@mui/joy";
import { ArrowBack, ArrowCircleLeft } from "@mui/icons-material";

export class EditItem extends Component {
  constructor(props) {
    super(props);
    this.state = {
      bodyFront: "",
      bodyBack: "",
      title: "",
      submit: false,
      awaiting: false,
    };
    this.viewMode = this.viewMode.bind(this);
    this.saveItem = this.saveItem.bind(this);
    this.titleChange = this.titleChange.bind(this);
    this.bodyFrontChange = this.bodyFrontChange.bind(this);
    this.bodyBackChange = this.bodyBackChange.bind(this);
  }
  titleChange(value) {
    const submit = !(value === "");
    this.setState({ title: value, submit: submit });
  }
  bodyFrontChange(value) {
    const submit = !(value === "");
    this.setState({ bodyFront: value, submit: submit });
  }
  bodyBackChange(value) {
    const submit = !(value === "");
    this.setState({ bodyBack: value, submit: submit });
  }
  viewMode() {
    this.setState({ awaitingEdit: false, mode: "view" });
    const redirect = `/seer/~${this.props.ship}/${this.props.stackId}/${this.props.itemId}`;
    this.props.history.push(redirect, { mode: "view" });
  }
  saveItem() {
    const { props, state } = this;

    this.props.setSpinner(true);
    const permissions = {
      read: {
        mod: "black",
        who: [],
      },
      write: {
        mod: "white",
        who: [],
      },
    };

    const data = {
      "edit-item": {
        who: props.ship,
        stak: props.stackId,
        name: props.itemId,
        title: state.title,
        perm: permissions,
        front: state.bodyFront,
        back: state.bodyBack,
      },
    };

    this.setState(
      {
        awaitingEdit: {
          ship: this.state.ship,
          stackId: this.props.stackId,
          itemId: this.props.itemId,
        },
      },
      () => {
        this.props.api.action("seer", "seer-action", data);
        this.setState({ awaiting: false, mode: "view" });
        const redirect = `/seer/~${props.ship}/${props.stackId}`;
        props.history.push(redirect);
      }
    );
  }
  componentDidMount() {
    const { props } = this;
    const stack = props.pubs[props.stackId];
    const content = stack.items[props.itemId].content;
    const title = content.title;
    const front = content.front;
    const back = content.back;
    const bodyFront = front.slice(front.indexOf(";>") + 3);
    const bodyBack = back.slice(back.indexOf(";>") + 3);
    this.setState({
      bodyFront: bodyFront,
      bodyBack: bodyBack,
      stack: stack,
      title: title,
    });
  }

  render() {
    const { props, state } = this;
    const options = {
      lineNumbers: false,
      lineWrapping: true,
      cursorHeight: 0.85,
    };

    /* let stackLinkText = `<- Back to ${this.state.stack.info.title}`; */
    let date = dateToDa(new Date(props.item.content["date-created"]));
    date = date.slice(1, -10);
    const submitStyle = state.submit
      ? { color: "#2AA779", cursor: "pointer" }
      : { color: "#B1B2B3", cursor: "auto" };

    return (
      <Grid
        sx={{ marginLeft: 2, width: "80%" }}
        display="flex"
        alignContent="flex-start"
        justifyContent="space-evenly"
        container
        spacing={2}
      >
        <Stack
          sx={{ p: 2 }}
          display="flex"
          direction="column"
          alignItems="flex-start"
          justifyItems="space-between"
          width="50%"
        >
          <CodeMirror
            width="100%"
            basicSetup={{
              lineNumbers: false,
            }}
            placeholder="Title"
            className="EditItem"
            extensions={[emacs(), markdown({ base: markdownLanguage })]}
            value={props.title}
            options={{ ...options }}
            onChange={(editor, value) => {
              this.titleChange(editor);
            }}
          />
          <CodeMirror
            width="100%"
            placeholder={"Front"}
            basicSetup={{
                lineNumbers: false,
            }}
            extensions={[
              emacs(),
              markdown({ base: markdownLanguage }),
            ]}
            value={state.bodyFront}
            options={{ ...options }}
            onChange={(e, v) => {
              this.bodyFrontChange(e);
            }}
          />
          <CodeMirror
            width="100%"
            placeholder={"Back"}
            basicSetup={{
                lineNumbers: false,
            }}
            extensions={[
              emacs(),
              markdown({ base: markdownLanguage }),
            ]}
            value={state.bodyBack}
            options={{ ...options }}
            onChange={(e, v) => {
              this.bodyBackChange(e);
            }}
          />
          <Stack direction="row" spacing={2}>
          <Link
            to={`/seer/${props.stack.info.owner}/${props.stack.info.filename}`}
          >
            <IconButton variant="soft" color="neutral">
              <ArrowCircleLeft /> {props.stack.info.filename}
            </IconButton>
          </Link>

          <IconButton variant="soft" color="neutral" onClick={this.viewMode}>
            <ArrowCircleLeft /> {props.item.content.title}
          </IconButton>
          </Stack>
        </Stack>

        <Stack
          sx={{ alignItems: "flex-start", p: 2, float: "right" }}
          spacing={2}
        >
          <Button
            disabled={!state.submit}
            onClick={this.saveItem}
            variant="soft"
          >
            Save {props.title}
          </Button>
        
        </Stack>
      </Grid>
    );
  }
}
