import { Button, Card, Stack, styled } from "@mui/joy";
import React, { Component } from "react";
import ReactMarkdown from "react-markdown";
import { width } from "@mui/system";
const RecallCard = styled(Card)(({ theme }) => ({
  backgroundColor: theme.palette.mode === "dark" ? "#1A2027" : "#fff",
  ...theme.typography.body2,
  padding: theme.spacing(1),
  overflowWrap: "anywhere",
  textAlign: "center",
  color: theme.palette.text.primary,
}));
export class ItemBody extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const front = this.props.bodyFront;
    const back = this.props.bodyBack;
    const newFront = front.slice(front.indexOf(";>") + 2).trim();
    const newBack = back.slice(back.indexOf(";>") + 2).trim();
    if (this.props.showBack) {
      return (
        <Stack sx={{ p: 2 }} spacing={2}>
          <RecallCard variant="outlined">
            <ReactMarkdown children={newFront} />
          </RecallCard>
          <RecallCard variant="outlined">
            <ReactMarkdown children={newBack} />
          </RecallCard>
          <Button
            variant="outlined"
            onClick={() => {
              this.props.toggleShowBack();
            }}
          >
            hide
          </Button>
        </Stack>
      );
    } else {
      return (
        <Stack sx={{ p: 2 }} spacing={2}>
          <RecallCard variant="outlined">
            <ReactMarkdown children={newFront} />
          </RecallCard>
          <Button
            variant="soft"
            onClick={() => {
              this.props.toggleShowBack();
            }}
          >
            reveal
          </Button>
        </Stack>
      );
    }
  }
}
