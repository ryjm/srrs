import React, { Component } from 'react';
import classnames from 'classnames';
import moment from 'moment';
import { Link } from 'react-router-dom';
import ReactMarkdown from 'react-markdown';

export class ItemBody extends Component {
  constructor(props){
    super(props)
  }


  render() {
    let file = this.props.body
    let newfile = file.slice(file.indexOf(';>')+2);
    return (
  <div className="md">
    <ReactMarkdown source={newfile} />
  </div>
    )
  }
}

