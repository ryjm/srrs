export class UpdateReducer {
    reduce(json, state) {
        const data = json.update || false;
        if (data) {
          this.reduceInbox(data.inbox || false, state);
        }
    }

    reduceInbox(inbox, state) {
        if (inbox) {
            state.inbox = inbox;
        }
    }
}
