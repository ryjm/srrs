import React, { Component } from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import { api } from '/api';
import { store } from '/store';
import { Review } from '/components/review';
import { NewStack } from '/components/new-stack';
import { NewItem } from '/components/new-item';
import { Skeleton } from '/components/skeleton';
import { Stack } from '/components/stack';
import { Item } from '/components/item';
import { Subs } from '/components/subs';
import { Pubs } from '/components/pubs';
import { Switch } from 'react-router';

export class Root extends Component {
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
      <BrowserRouter>
        <Switch>
          <Route
            exact
            path="/~srrs/review"
            render={(props) => {
              return (
                <Skeleton
                  pubs={state.pubs}
                  subs={state.subs}
                  api={api}
                  spinner={this.state.spinner}
                  active="sidebar"
                >
                  <Review {...props} {...state} />
                </Skeleton>
              );
            }}
          />
          <Route
            exact
            path="/~srrs/:who/:stack/review"
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
            path="/~srrs/subs"
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
            path="/~srrs/pubs"
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
            path="/~srrs/new-stack"
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
            path="/~srrs/new-item"
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
            path="/~srrs/:ship/:stack/new-item"
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
            path="/~srrs/:ship/:stack"
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
            path="/~srrs/:ship/:stack/:item"
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
    );
  }
}
