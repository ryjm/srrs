import { withRouter } from "react-router";
import { Link, RouteComponentProps, useLocation } from "react-router-dom";
import { PathControl } from "../lib/path-control";
import { stringToSymbol } from "../lib/util";
import History from "history";
import API from "~/types/API";
import React from "react";

const PC = withRouter<IStackProps, any>(PathControl);
export interface IStackProps extends RouteComponentProps {
  setSpinner: (spin: boolean) => string;
  api: API;
  pubs: [];
  history: History.History;
}
type NewStackType = React.ComponentType<IStackProps>;

export interface HistoryItem {
  path: string;
  lastParams?: { ship: string; stack: string };
}
export interface IStackState {
  title: string;
  page: string;
  awaiting: string;
  disabled: boolean;
  redirect: string;
  pathData: [];
}

export default class NewStack extends React.Component<
  IStackProps,
  IStackState
> {
  titleHeight: number;
  titleInput: any;
  constructor(props: IStackProps) {
    super(props);

    this.state = {
      title: "",
      page: "main",
      awaiting: "false",
      disabled: false,
      redirect: "",
      pathData: [],
    };
    this.titleChange = this.titleChange.bind(this);
    this.firstItem = this.firstItem.bind(this);
    this.returnHome = this.returnHome.bind(this);
    this.stackSubmit = this.stackSubmit.bind(this);

    this.titleHeight = 52;
  }

  stackSubmit() {
    // @ts-ignore
    const ship = window.ship;
    const stackTitle = this.state.title;
    const stackId = stringToSymbol(stackTitle);

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

    const makeStack = {
      "new-stack": {
        name: stackId,
        title: stackTitle,
        items: null,
        edit: "all",
        perm: permissions,
      },
    };

    this.setState({
      awaiting: stackTitle,
    });

    this.props.setSpinner(true);

    this.props.api.seer.action("seer", "seer-action", makeStack);

    // this.props.api.action("seer", "seer-action", sendInvites);
  }
  shouldComponentUpdate(
    nextProps: IStackProps,
    nextState: IStackState,
    nextContext
  ): boolean {
    if (nextState.redirect !== this.state.redirect) {
      return true;
    }
    if (nextState.awaiting != this.state.awaiting) return true;
    if (nextState.title != this.state.title) return true;
    else return false;
  }
  componentDidUpdate(prevProps, prevState) {
    console.log(prevState.awaiting);
    if (this.state.redirect === "new-item") {
      this.props.history.push({
        path: "/seer/review",
        lastParams: {
          // @ts-ignore TODO window typings
          ship: `~${window.ship}`,
          stack: this.state.awaiting,
        }
      });
      return
    } else if (this.state.redirect === "home") {
      // @ts-ignore TODO window typing
      this.props.history.push(`/seer/~${window.ship}/${this.state.awaiting}`);
    }
  }

  titleChange(evt) {
    this.titleInput.style.height = "auto";
    this.titleInput.style.height =
      this.titleInput.scrollHeight < 52 ? 52 : this.titleInput.scrollHeight;
    this.titleHeight = this.titleInput.style.height;

    this.setState({ title: evt.target.value });
  }

  firstItem() {
    this.setState({ redirect: "new-item" });
    this.stackSubmit();
  }

  returnHome() {
    this.setState({ redirect: "home" });
    this.stackSubmit();
  }

  render() {
    if (this.state.page === "main") {
      let createClasses =
        "pointer db f9 green2 bg-gray0-d ba pv3 ph4 mv7 b--green2";
      let outerName =
        "h-100 w-100 mw6 pa3 pt4 overflow-x-hidden flex flex-column white-d";
      if (!this.state.title || this.state.disabled) {
        createClasses = "db f9 gray2 ba bg-gray0-d pa2 pv3 ph4 mv7 b--gray3";
      }

      return (
        <div className={outerName}>
          <div className="w-100 dn-m dn-l dn-xl inter pt1 pb6 f8">
            <Link to="/seer/review">{"⟵ review"}</Link>
          </div>
          <div className="w-100">
            <p className="f9 gray2 db mb2 pt1">stack name</p>
            <textarea
              autoFocus
              ref={(el) => {
                this.titleInput = el;
              }}
              className={
                "f7 ba bg-gray0-d white-d pa3 db w-100 " +
                "focus-b--black focus-b--white-d b--gray3 b--gray2-d"
              }
              style={{ resize: "none" }}
              rows={1}
              name="stackName"
              placeholder="add a title"
              onChange={this.titleChange}
            ></textarea>
            <button
              disabled={this.state.disabled}
              onClick={this.firstItem}
              className={createClasses}
            >
              create
            </button>
          </div>
        </div>
      );
    }
  }
}
