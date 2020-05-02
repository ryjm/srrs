import _ from 'lodash';

export class ResponseReducer {
  reduce(json, state) {
    switch(json.type) {
      case "local":
        this.sidebarToggle(json, state);
        this.setSelected(json, state);
        break;
      default:
        break;
    }
  }

  sidebarToggle(json, state) {
    let data = _.has(json.data, 'sidebarToggle', false);
    if (data) {
        state.sidebarShown = json.data.sidebarToggle;
    }
  }

  setSelected(json, state) {
    let data = _.has(json.data, 'selected', false);
    if (data) {
      state.selectedGroups = json.data.selected;
    }
  }

}
