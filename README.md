spaced repetition repetition system
---

An Urbit agent that provides spaced repetitition functionality similar to [Anki](https://apps.ankiweb.net/) with a Landscape and CLI interface to the app. Supports importing from other ships and importing from Anki (from `srrs-cli`).

[![awesome urbit badge](https://img.shields.io/badge/~-awesome%20urbit-lightgrey)](https://github.com/urbit/awesome-urbit)

##### Landscape and CLI UI
![UI](srrs.gif)


on urbit: `|merge %home ~middev %kids`

from source: 

install node and npm

mount your urbit with `|mount %` in the dojo - you should see your files in unix under `/path/to/pier/home`

change `config/urbitrc-sample' to point your mounted files (`path/to/pier/home`) and rename to `urbitrc` 

install with `npm install`

run with `npm run build:dev`, and check that the `srrs` files appear under `home/app/srrs`

in the dojo, run `|commit %home` to get urbit to see the added files - you should see the added files in the output

start with `|start %srrs`

#### Usage

- start with `|start %srrs` in the dojo
- to  use `srrs-cli`, start it with `|start %srrs-cli` and `|link %srrs-cli`,
switch to it with C-x. create a private channel called `srrs` for notifications
to show up in chat.
  - tab complete for commands starting with `;`
  
##### Importing from anki

Note that this currently only supports decks with two fields, like this one: [Hoon Rune Families](https://ankiweb.net/shared/info/227862017)

  - export your deck to text file and place it in your urbit pier
  - run `|commit %home`
  - run `;import-file /path/to/file/txt` from `srrs-cli`
  
##### Subscribing to other stacks

  - import stacks from other planets with the `;import [ship] [stack]` command
  - this will add shared stacks to a read-only (at least from the UI) set of
    subscribed stacks.
      - when you review an item, it will be copied to your personal stacks. 
      - you can also use the Review All button to add every item to your review list.
  - NOTE: all decks are currently public! permissioning to come soon. 

#### Troubleshooting

dm `~littel-wolfur` if you're having any other issues, or create an issue here.


**TODO:**
- ~~handle the scheduling of review items~~
- ~~support creating stacks/items through frontend~~
- ~~tile~~
- ~~remove old publish artifacts (almost done)~~
- ~~clean up sur and lib, move to json in mar (started)~~
- ~~update landscape UI to OS1 style, probably just a full rewrite~~
- less shitty
