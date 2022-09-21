import { ThirtyFpsSelect } from "@mui/icons-material";
import { Button } from "@mui/joy";
import React, { Component } from "react";
import { PathControl } from "../lib/path-control";

export class NotFound extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const pathData = [{ text: "Home", url: "/seer/review" }];
    const backText = "<- Back";

    const back = this.props.history ? (
      <p
        className="body-regular pointer"
        style={{ marginTop: 22 }}
        onClick={() => {
          this.props.history.goBack();
          
        }}
      >
        {backText}
      </p>
    ) : null;

    return (
      <div>
        <PathControl pathData={pathData} create={false} />
        <div className="absolute w-100" style={{ top: 124 }}>
          <Button size="lg" variant="outlined" color="secondary">
            {back}
          </Button>
            <h2>Page Not Found</h2>
        </div>
      </div>
    );
  }
}
