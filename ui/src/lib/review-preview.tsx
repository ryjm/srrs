import { Article } from '@mui/icons-material';
import { Button, Chip, Stack, styled, Typography } from '@mui/joy';
import { Paper, Tooltip, tooltipClasses, TooltipProps } from '@mui/material';
import moment from 'moment';
import React, { Component } from 'react';
import { Link } from 'react-router-dom';

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
      backgroundColor: theme.palette.mode === "dark" ? "#1A2027" : "#fff",
      color: "rgba(0, 0, 0, 0.87)",
      maxWidth: 220,
      border: "1px solid #dadde9",
    },
  }));
  const tooltip = (
    <React.Fragment>
      <Stack spacing={1}>
        <Part>
          <b>Last Reviewed</b>: {lastReview}
        </Part>
        <Part>
          <b>Spacing</b>: {interval}
        </Part>
        <Chip startDecorator={<Article />} variant="outlined" color="primary">
          {props.item.stackTitle}
        </Chip>
      </Stack>
    </React.Fragment>
  );
  return (
    <HtmlTooltip title={tooltip}>
      <Link to={loc}>
        <Button variant='plain'>
          <Part>
          <Typography>
          {props.item.itemSnippet}
          </Typography>
          </Part>
          </Button>
      </Link>
    </HtmlTooltip>
  );
}
export default ReviewPreview;
