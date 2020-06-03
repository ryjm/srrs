import _ from 'lodash';

export class PrimaryReducer {
  reduce(json, state){
    switch(Object.keys(json)[0]){
    case "add-item":
      this.addItem(json["add-item"], state);
      break
    case "add-stack":
      this.addStack(json["add-stack"], state);
      break
    case "update-review":
      this.updateReview(json["update-review"], state);
      break
    case "add-review-item":
      this.addRaisedItem(json["add-review-item"], state);
      break
    case "delete-review-item":
      this.deleteReviewItem(json["delete-review-item"], state);
      break
    case "delete-stack":
      this.deleteStack(json["delete-stack"], state);
      break
    case "update-stack":
      this.addStack(json["update-stack"], state);
    default:
      break
    }
  }

  addItem(json, state) {
    let host   = Object.keys(json)[0];
    let stack   = Object.keys(json[host])[0];
    let noteId = json[host][stack].name;
    if (state.pubs && state.pubs[stack]) {
      if (state.pubs[stack].items) {
        state.pubs[stack].items[noteId] = json[host][stack];
      } else {
        state.pubs[stack].items = {[noteId]: json[host][stack]};
      }

    }
  }
  addStack(json, state) {
    let host   = Object.keys(json)[0];
    let stack   = Object.keys(json[host])[0];
    if (state.pubs) {
      state.pubs[stack] = json[host][stack];

    }
  }
  deleteStack(json, state) {
    let host = json["who"].slice(1);
    if (state.subs[host]) {
      delete state.subs[host][json["stack"]];
    }
    else if (state.pubs) {
      if (state.pubs[json["stack"]].info.owner === host) {
        delete state.pubs[json["stack"]];
      }
    }
  }

  updateReview(json, state) {
    state.review=json
  }

  addRaisedItem(json, state) {
    state.review.push(json)
  }
  deleteReviewItem(json, state) {
    let idx = state.review.findIndex(item => ((item.who === json.who.slice(1)) || (item.who === json.who)) && (item.stack === json.stack) && (item.item === json.item))
    if (idx === -1) {
      return state.review
    } else {
      state.review.splice( idx, 1 );
    }
  }
}
