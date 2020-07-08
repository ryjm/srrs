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
    if (json.data.hasOwnProperty('sidebarToggle')) {
      state.sidebarShown = json.data.sidebarToggle;
    }
  }

  setSelected(json, state) {
    if (json.data.hasOwnProperty('selected')) {
      state.selectedGroups = json.data.selected;
    }
  }

}
