import React, { Component } from "react";
import "../index.css";
import styled, { ThemeProvider, createGlobalStyle } from "styled-components";

import { BrowserRouter, Route } from "react-router-dom";
import api from "../api";
import { store } from "../store";
import { Review } from "./review";
import NewStack from "./new-stack";
import { NewItem } from "./new-item";
import Skeleton from "./skeleton";
import { Stack } from "./stack";
import { Item } from "./item";
import { Subs } from "./subs";
import { Pubs } from "./pubs";
import { Switch } from "react-router";
import { deepmerge } from "@mui/utils";
import type {} from "@mui/material/themeCssVarsAugmentation";
import {
  experimental_extendTheme as extendMuiTheme,
  PaletteColor,
  TypeText,
  TypeAction,
  Overlays,
  PaletteColorChannel,
  PaletteAlert,
  PaletteAppBar,
  PaletteAvatar,
  PaletteChip,
  PaletteFilledInput,
  PaletteLinearProgress,
  PaletteSlider,
  PaletteSkeleton,
  PaletteSnackbarContent,
  PaletteSpeedDialAction,
  PaletteStepConnector,
  PaletteStepContent,
  PaletteSwitch,
  PaletteTableCell,
  PaletteTooltip,
  Shadows,
  ZIndex,
  SxProps,
} from "@mui/material/styles";
import colors from "@mui/joy/colors";
import {
  extendTheme as extendJoyTheme,
  CssVarsProvider,
  useColorScheme,
  Theme as JoyTheme,
  ThemeCssVar as JoyThemeCssVar,
} from "@mui/joy/styles";

// Material UI components
import Button from "@mui/material/Button";

// Icons
import DarkMode from "@mui/icons-material/DarkMode";
import LightMode from "@mui/icons-material/LightMode";

// Joy UI components
import AspectRatio from "@mui/joy/AspectRatio";
import Box from "@mui/joy/Box";
import JoyButton from "@mui/joy/Button";
import IconButton from "@mui/joy/IconButton";
import Card from "@mui/joy/Card";
import Typography from "@mui/joy/Typography";
import { CommonColors } from "@mui/material/styles/createPalette";
import { Fab, TypeBackground } from "@mui/material";

// extends Joy theme to include tokens from Material UI
declare module "@mui/joy/styles" {
  interface Palette {
    secondary: PaletteColorChannel;
    error: PaletteColorChannel;
    dividerChannel: string;
    action: TypeAction;
    Alert: PaletteAlert;
    AppBar: PaletteAppBar;
    Avatar: PaletteAvatar;
    Chip: PaletteChip;
    FilledInput: PaletteFilledInput;
    LinearProgress: PaletteLinearProgress;
    Skeleton: PaletteSkeleton;
    Slider: PaletteSlider;
    SnackbarContent: PaletteSnackbarContent;
    SpeedDialAction: PaletteSpeedDialAction;
    StepConnector: PaletteStepConnector;
    StepContent: PaletteStepContent;
    Switch: PaletteSwitch;
    TableCell: PaletteTableCell;
    Tooltip: PaletteTooltip;
  }
  interface PalettePrimary extends PaletteColor {}
  interface PaletteInfo extends PaletteColor {}
  interface PaletteSuccess extends PaletteColor {}
  interface PaletteWarning extends PaletteColor {}
  interface PaletteCommon extends CommonColors {}
  interface PaletteText extends TypeText {}
  interface PaletteBackground extends TypeBackground {}

  interface ThemeVars {
    // attach to Joy UI `theme.vars`
    shadows: Shadows;
    overlays: Overlays;
    zIndex: ZIndex;
  }
}

type MergedThemeCssVar = { [k in JoyThemeCssVar]: true };

declare module "@mui/material/styles" {
  interface Theme {
    // put everything back to Material UI `theme.vars`
    vars: JoyTheme["vars"];
  }

  // makes Material UI theme.getCssVar() sees Joy theme tokens
  interface ThemeCssVarOverrides extends MergedThemeCssVar {}
}

const ModeToggle = () => {
  const { mode, setMode } = useColorScheme();
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => {
    setMounted(true);
  }, []);
  if (!mounted) {
    return null;
  }
  const fabStyle = {
    position: 'absolute',
    bottom: 16,
    right: 16,
  };
  return (
    <Fab size="small" sx={fabStyle as SxProps} onClick={() => setMode(mode === "dark" ? "light" : "dark")}>
      {mode === "dark" ? <DarkMode /> : <LightMode />}
    </Fab>
  );
};

const muiTheme = extendMuiTheme({
  cssVarPrefix: "joy",
  colorSchemes: {
    light: {
      palette: {
        primary: {
          main: colors.blue[500],
        },
        grey: colors.grey,
        error: {
          main: colors.red[500],
        },
        info: {
          main: colors.purple[500],
        },
        success: {
          main: colors.green[500],
        },
        warning: {
          main: colors.yellow[200],
        },
        common: {
          white: "#FFF",
          black: "#09090D",
        },
        divider: colors.grey[200],
        text: {
          primary: colors.grey[800],
          secondary: colors.grey[600],
        },
      },
    },
    dark: {
      palette: {
        primary: {
          main: colors.blue[600],
        },
        grey: colors.grey,
        error: {
          main: colors.red[600],
        },
        info: {
          main: colors.purple[600],
        },
        success: {
          main: colors.green[600],
        },
        warning: {
          main: colors.yellow[300],
        },
        common: {
          white: "#FFF",
          black: "#09090D",
        },
        divider: colors.grey[800],
        text: {
          primary: colors.grey[100],
          secondary: colors.grey[300],
        },
      },
    },
  },
});

const joyTheme = extendJoyTheme();
const Root = styled.div`
  font-family: ${(p) => p.theme.fonts.sans};
  height: 100%;
  width: 100%;
  padding: 0;
  margin: 0;
  ${(p) =>
    p.background?.type === "url"
      ? `
    background-image: url('${p.background?.url}');
    background-size: cover;
    `
      : p.background?.type === "color"
      ? `
    background-color: ${p.background.color};
    `
      : ""}
  display: flex;
  flex-flow: column nowrap;

  * {
    scrollbar-width: thin;
    scrollbar-color: ${(p) => p.theme.colors.gray}
      ${(p) => p.theme.colors.white};
  }

  /* Works on Chrome/Edge/Safari */
  *::-webkit-scrollbar {
    width: 12px;
  }
  *::-webkit-scrollbar-track {
    background: transparent;
  }
  *::-webkit-scrollbar-thumb {
    background-color: ${(p) => p.theme.colors.gray};
    border-radius: 1rem;
    border: 3px solid ${(p) => p.theme.colors.white};
  }
`;
export class App extends Component {
  constructor(props) {
    super(props);
    this.state = store.state;
    store.setStateHandler(this.setState.bind(this));

    this.setSpinner = this.setSpinner.bind(this);
  }

  setSpinner(spinner) {
    this.setState({
      spinner,
    });
  }

  render() {
    const { state } = this;
    return (
      <CssVarsProvider theme={deepmerge(joyTheme, muiTheme)}>
        
        <BrowserRouter>
          <Switch>
            <Route
              exact
              path="/seer/review"
              render={(props) => {
                return (
                  <Skeleton
                    pubs={state.pubs}
                    subs={state.subs}
                    api={api}
                    spinner={this.state.spinner}
                    active="sidebar"
                    popout={false}
                    {...state}
                  >
                    <Review {...props} {...state} />
                  </Skeleton>
                );
              }}
            />
            <Route
              exact
              path="/seer/:who/:stack/review"
              render={(props) => {
                return (
                  <Skeleton
                    pubs={state.pubs}
                    subs={state.subs}
                    api={api}
                    spinner={this.state.spinner}
                    active="sidebar"
                    {...state}
                  >
                    <Review
                      {...props}
                      {...state}
                      stack={props.match.params.stack}
                      who={props.match.params.who}
                    />
                  </Skeleton>
                );
              }}
            />
            <Route
              exact
              path="/seer/subs"
              render={(props) => {
                return (
                  <Skeleton
                    spinner={this.state.spinner}
                    active="sidebar"
                    {...state}
                  >
                    <Subs {...this.state} api={api} />
                  </Skeleton>
                );
              }}
            />
            <Route
              exact
              path="/seer/pubs"
              render={(props) => {
                return (
                  <Skeleton
                    spinner={this.state.spinner}
                    pubs={state.pubs}
                    subs={state.subs}
                    active="sidebar"
                    {...state}
                  >
                    <Pubs {...state} />
                  </Skeleton>
                );
              }}
            />

            <Route
              exact
              path="/seer/new-stack"
              render={(props) => {
                return (
                  <Skeleton
                    spinner={this.state.spinner}
                    pubs={state.pubs}
                    subs={state.subs}
                    {...state}
                  >
                    <NewStack
                      api={api}
                      {...this.state}
                      setSpinner={this.setSpinner}
                      {...props}
                      {...state}
                    />
                  </Skeleton>
                );
              }}
            />

            <Route
              exact
              path="/seer/new-item"
              render={(props) => {
                return (
                  <Skeleton
                    spinner={this.state.spinner}
                    pubs={state.pubs}
                    subs={state.subs}
                    active="sidebar"
                    {...state}
                  >
                    <NewItem
                      api={api}
                      {...this.state}
                      setSpinner={this.setSpinner}
                      {...props}
                    />
                  </Skeleton>
                );
              }}
            />

            <Route
              exact
              path="/seer/:ship/:stack/new-item"
              render={(props) => {
                return (
                  <Skeleton
                    spinner={this.state.spinner}
                    pubs={state.pubs}
                    subs={state.subs}
                    active="sidebar"
                    {...state}
                  >
                    <NewItem
                      api={api}
                      {...this.state}
                      stack={props.match.params.stack}
                      ship={props.match.params.ship}
                      setSpinner={this.setSpinner}
                      {...props}
                    />
                  </Skeleton>
                );
              }}
            />

            <Route
              exact
              path="/seer/:ship/:stack"
              render={(props) => {
                return (
                  <Skeleton
                    spinner={this.state.spinner}
                    pubs={state.pubs}
                    subs={state.subs}
                    path={props.match.params.stack}
                    active="sidebar"
                    api={api}
                    {...state}
                  >
                    <Stack
                      view="notes"
                      stackId={props.match.params.stack}
                      ship={props.match.params.ship.slice(1)}
                      api={api}
                      setSpinner={this.setSpinner}
                      {...this.state}
                      {...props}
                    />
                  </Skeleton>
                );
              }}
            />

            <Route
              exact
              path="/seer/:ship/:stack/:item"
              render={(props) => {
                return (
                  <Skeleton
                    spinner={this.state.spinner}
                    pubs={state.pubs}
                    subs={state.subs}
                    active="sidebar"
                    {...state}
                  >
                    <Item
                      stackId={props.match.params.stack}
                      itemId={props.match.params.item}
                      ship={props.match.params.ship.slice(1)}
                      setSpinner={this.setSpinner}
                      api={api}
                      {...this.state}
                      {...props}
                    />
                  </Skeleton>
                );
              }}
            />
          </Switch>
        </BrowserRouter>
        <ModeToggle  />
      </CssVarsProvider>
    );
  }
}
