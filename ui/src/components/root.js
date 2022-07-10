import React, { Component } from 'react';
import '../index.css';
import styled, { ThemeProvider, createGlobalStyle } from 'styled-components';
import light from '@tlon/indigo-light';
import { BrowserRouter, Route } from 'react-router-dom';
import api from '../api';
import { store } from '../store';
import { Review } from '../components/review';
import NewStack from '../components/new-stack';
import { NewItem } from '../components/new-item';
import { Skeleton } from '../components/skeleton';
import { Stack } from './stack';
import { Item } from './item';
import { Subs } from './subs';
import { Pubs } from './pubs';
import { Switch } from 'react-router';
const Root = styled.div`
  font-family: ${p => p.theme.fonts.sans};
  height: 100%;
  width: 100%;
  padding: 0;
  margin: 0;
  ${p => p.background?.type === 'url' ? `
    background-image: url('${p.background?.url}');
    background-size: cover;
    ` : p.background?.type === 'color' ? `
    background-color: ${p.background.color};
    ` : ''
  }
  display: flex;
  flex-flow: column nowrap;

  * {
    scrollbar-width: thin;
    scrollbar-color: ${ p => p.theme.colors.gray } ${ p => p.theme.colors.white };
  }

  /* Works on Chrome/Edge/Safari */
  *::-webkit-scrollbar {
    width: 12px;
  }
  *::-webkit-scrollbar-track {
    background: transparent;
  }
  *::-webkit-scrollbar-thumb {
    background-color: ${ p => p.theme.colors.gray };
    border-radius: 1rem;
    border: 3px solid ${ p => p.theme.colors.white };
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
      spinner
    });
  }

  render() {
    const { state } = this;
    return (
      <ThemeProvider theme={light}>
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
                >
                  <Review {...props} {...state} stack={props.match.params.stack} who={props.match.params.who} />
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
                >
                  <NewStack
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
            path="/seer/new-item"
            render={(props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  pubs={state.pubs}
                  subs={state.subs}
                  active="sidebar"
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
      </ThemeProvider>
    );
  }
}
