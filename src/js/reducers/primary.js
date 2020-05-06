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
    default:
      break
    }
  }

  addItem(json, state) {
    let host   = Object.keys(json)[0];
    let stack   = Object.keys(json[host])[0];
    let noteId = json[host][stack].content["note-id"];
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

  updateReview(json, state) {
    console.log("in update")
    console.log(json)
    state.review=json
  }

}
