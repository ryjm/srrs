export class ResponseReducer {
  reduce(json, state) {
    switch(json.type) {
      case 'local':
        this.sidebarToggle(json, state);
        this.setSelected(json, state);
        break;
      default:
        break;
    }
  }

  sidebarToggle(json, state) {
    if (Object.prototype.hasOwnProperty.call(json.data, 'sidebarToggle')) {
      state.sidebarShown = json.data.sidebarToggle;
    }
  }

  setSelected(json, state) {
    if (Object.prototype.hasOwnProperty.call(json.data, 'selected')) {
      state.selectedGroups = json.data.selected;
    }
  }

}
