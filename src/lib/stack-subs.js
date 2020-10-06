import React, { Component } from 'react';

export class StackSubs extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    const back = '<- Back to notes';

    const subscribers = this.props.subs.map((sub, i) => {
      return (
        <div className="flex w-100" key={i+1}>
          <p className="label-regular-mono w-100">~{sub}</p>
        </div>
      );
    });

    subscribers.unshift(
      <div className="flex w-100" key={0}>
        <p className="label-regular-mono w-100">~{window.ship}</p>
        <p className="label-regular-mono w-100">Host (You)</p>
      </div>
    );

    return (
      <div className="flex-col mw-688" style={{ marginTop: 48 }}>
        <hr className="gray-30" style={{ marginBottom: 25 }} />
        <p className="label-regular pointer b" onClick={this.props.back}>
          {back}
        </p>
        <p className="body-large b" style={{ marginTop: 16, marginBottom: 20 }}>
          Manage Notebook
        </p>
        <div className="flex">
          <div className="flex-col w-100">
            <p className="body-regular-400">Members</p>
            <p className="gray-50 label-small-2"
              style={{ marginTop: 12, marginBottom: 23 }}
            >
              Everyone subscribed to this notebook
            </p>
            {subscribers}
          </div>
        </div>
      </div>
    );
  }
}
