import React, { Component } from "react";
import moment from "moment";
import { Link } from "react-router-dom";
import { ItemSnippet } from "./item-snippet";
import momentConfig from "../config/moment";
import {
  Button,
  styled,
  Tooltip,
  TooltipProps,
  tooltipClasses,
  Paper,
  Typography,
  Stack,
  Chip,
} from "@mui/material";
import { Article } from "@mui/icons-material";
const Part = styled(Paper)(({ theme }) => ({
  backgroundColor: theme.palette.mode === "dark" ? "#1A2027" : "#fff",
  ...theme.typography.body2,
  padding: theme.spacing(1),
  textAlign: "center",
  color: theme.palette.text.secondary,
}));

function ReviewPreview(props) {
  const date = moment(props.item.date).fromNow();
  const lastReview =
    props.item.lastReview === null
      ? "never"
      : moment(props.item.lastReview).fromNow();
  const interval = props.item.learn.interval.split(".").slice(0, 2).join(".");
  const author = props.item.author;
  const stackLink = "/seer/" + props.item.author + "/" + props.item.stackName;
  const itemLink = stackLink + "/" + props.item.itemName;
  const loc = {
    pathname: itemLink,
    state: {
      reviews: props.reviews,
      next: props.next,
      idx: props.idx,
      mode: "review",
      prevPath: location.pathname,
    },
  };
  const HtmlTooltip = styled(({ className, ...props }: TooltipProps) => (
    <Tooltip {...props} classes={{ popper: className }} />
  ))(({ theme }) => ({
    [`& .${tooltipClasses.tooltip}`]: {
      backgroundColor: "#f5f5f9",
      color: "rgba(0, 0, 0, 0.87)",
      maxWidth: 220,
      fontSize: theme.typography.pxToRem(12),
      border: "1px solid #dadde9",
    },
  }));
  const tooltip = (
    <React.Fragment>
      <Stack spacing={1}>
        <Part><b>Last Reviewed</b>: {lastReview}</Part>
        <Part><b>Spacing</b>: {interval}</Part>
        <Chip label={props.item.stackTitle} color="info" icon={<Article />} />

      </Stack>
    </React.Fragment>
  );
  return (
    <Link to={loc} className="light mv2 link db mw5 pa2 br2 ma2">
      <HtmlTooltip title={tooltip}>
        <Button>{props.item.itemSnippet}</Button>
      </HtmlTooltip>
    </Link>

    /*     <Link to={loc}>
        <div className="f9 lh-solid ml3 flex">
          <div className="flex-wrap">
            <div className="mv2 link black dim db mw5 pa2 br2 bt b--green0 shadow-hover ma2">
            <div className="flex">
              <div className="blue1 mr2">{props.item.itemSnippet}</div>
              <div className="green3 ml2">{interval}</div>
            </div>
              <div className="flex">
              <div className="gray2 mr2">{lastReview}</div>
                <Link to={stackLink}>
                  <div className="blue3 mr2">{props.item.stackTitle}</div>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </Link> */
  );
}
export default ReviewPreview;
