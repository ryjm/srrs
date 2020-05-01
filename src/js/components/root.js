import React, { Component } from 'react';
import { BrowserRouter, Route } from "react-router-dom";
import classnames from 'classnames';
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

    return (
      <BrowserRouter>
        <Switch>
          <Route exact path="/~srrs/review"
            render={ (props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  children={
                    <Review {...this.state} />
                  }
                />
              );
           }} />
          <Route exact path="/~srrs/subs"
            render={ (props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  children={
                    <Subs {...this.state} api={api}/>
                  }
                />
              );
           }} />
          <Route exact path="/~srrs/pubs"
            render={ (props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  children={
                    <Pubs {...this.state} />
                  }
                />
              );
           }} />

          <Route exact path="/~srrs/new-stack"
            render={ (props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  children={
                    <NewStack api={api}
                      {...this.state}
                      setSpinner={this.setSpinner}
                      {...props}/>
                  }
                />
              );
           }} />

          <Route exact path="/~srrs/new-item"
            render={ (props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  children={
                    <NewItem api={api}
                      {...this.state}
                      setSpinner={this.setSpinner}
                      {...props}/>
                  }
                />
              );
           }} />

          <Route exact path="/~srrs/:ship/:stack"
            render={ (props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  children={
                    <Stack
                      stackId = {props.match.params.stack}
                      ship = {props.match.params.ship.slice(1)}
                      api = {api}
                      setSpinner={this.setSpinner}
                      {...this.state}
                      {...props}
                    />
                  }
                />
              );
           }} />

          <Route exact path="/~srrs/:ship/:stack/:item"
            render={ (props) => {
              return (
                <Skeleton
                  spinner={this.state.spinner}
                  children={
                    <Item
                      stackId = {props.match.params.stack}
                      itemId = {props.match.params.item}
                      ship = {props.match.params.ship.slice(1)}
                      setSpinner={this.setSpinner}
                      api = {api}
                      {...this.state}
                      {...props}
                    />
                  }
                />
              );
           }} />
        </Switch>
      </BrowserRouter>
    );
  }
}
