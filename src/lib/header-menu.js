import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { SrrsCreate } from '~/lib/seer-create';
import { withRouter } from 'react-router';

const PC = withRouter(SrrsCreate);

export class HeaderMenu extends Component {
    constructor(props) {
    super(props);
  }

  render () {
    const tabStyles = {
      review: 'bb b--gray4 b--gray2-d gray2 pv4 ph2',
      stacks: 'bb b--gray4 b--gray2-d gray2 pv4 ph2',
      settings: 'bb b--gray4 b--gray2-d pr2 gray2 pv4 ph2'
    };
        return (
            <div
        className="overflow-y-scroll"
        style={{ paddingLeft: 16, paddingRight: 16 }}
        onScroll={this.onScroll}
        ref={(el) => {
          this.scrollElement = el;
              }}
            >
              <PC create={'stack'} />

        <div className="center mw6 f9 h-100"
          style={{ paddingLeft: 16, paddingRight: 16 }}
        >

            <div className="flex" style={{ marginBottom: 24 }}>
              <Link to="/seer/review" className={tabStyles.review}>
                Review
              </Link>
              <Link to="/seer/pubs" className={tabStyles.stacks}>
                Stacks
              </Link>
              <div className="bb b--gray4 b--gray2-d gray2 pv4 ph2"
                style={{ flexGrow: 1 }}
              ></div>
            </div>

          </div>
        </div>

    );
  }
}
