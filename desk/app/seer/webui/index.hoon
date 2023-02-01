::  seer index
::
/-  *seer, contact=contact-store
/+  rudder, sigil-svg=sigil
::
^-  (page:rudder records command)
::
=>  |%
    +$  role  ?(%all %mutual %target %leeche)
    --
::
|_  [=bowl:gall order:rudder records]
++  argue
  |=  [headers=header-list:http body=(unit octs)]
  ^-  $@(brief:rudder command)
  =/  args=(map @t @t)
    ?~(body ~ (frisk:rudder q.u.body))
  =/  toggle  (~(get by args) 'tog')
  ?~  what=(~(get by args) 'what')
    ~
  ?~  who=(slaw %p (~(gut by args) 'who' ''))
    'invalid ship name'
  ?:  =(u.who our.bowl)
    'befriend your inner self'
  |^  ?+  u.what  ?~(toggle 'say what now' 'toggled')
          ?(%dust %wipe)
        ?:  ?=(%wipe u.what)
          [%wipe u.who ~]
        =/  tags  get-lists
        ?~  tags  tag-error
        [%dust u.who u.tags]
      ::
          ?(%enlist %unlist)
        =/  tags  get-lists
        ?~  tags  tag-error
        ?:  =(~ u.tags)  'no-op'
        ?:  ?=(%enlist u.what)
          [%dust u.who u.tags]
        [%wipe u.who u.tags]
      ==
  ::
  ++  tag-error
    'tags must be in @ta (lowercase & url-safe) format and comma-separated'
  ::
  ++  get-lists
    ^-  (unit (set @ta))
    %+  rush  (~(gut by args) 'lists' '')
    %+  cook
      |=(s=(list @ta) (~(del in (~(gas in *(set @ta)) s)) ''))
    (more (ifix [. .]:(star ace) com) urs:ab)
  --
::
++  final  (alert:rudder url.request build)
::
++  build
  |=  $:  arg=(list [k=@t v=@t])
          msg=(unit [o=? =@t])
      ==
  ^-  reply:rudder
  ::
  =/  rel=role
    =/  a  (~(gas by *(map @t @t)) arg)
    =/  r  (~(gut by a) 'rel' %all)
    ?:(?=(role r) r %all)
  =/  tag=(set @ta)
    %-  sy
    %+  murn  arg
    |=  [k=@t v=@t]
    ?:(=('tag' k) (some v) ~)
  =/  tog=@t
    =-  (~(gut by -) 'tog' 'none')
    (~(gas by *(map @t @t)) arg)
  =/  toggled=@t
    ?:  =('block' tog)
      'none'
    'block'
  ::  =/  toggled=@t  %+  fall  (bind msg |=([o=? a=@t] ?:(=('block' a) 'none' 'block')))  'block'
  ::
  |^  [%page page]
  ::
  ++  icon-color  "black"
  ::
  ++  style
    '''
    * { margin: 0.2em; padding: 0.2em; font-family: monospace; }

    p { max-width: 50em; }

    form { margin: 0; padding: 0; }

    .red { font-weight: bold; color: #dd2222; }
    .green { font-weight: bold; color: #229922; }

    a {
      display: inline-block;
      color: inherit;
      padding: 0;
      margin-top: 0;
    }

    .seer-box {
      max-width: fit-content;
      background-color: #ccc;
      border-radius: 3px;
      padding: 0.1em;
      font-style: italic;
      white-space: pre-line;
    }
    .class-filter a {
      background-color: #ccc;
      border-radius: 3px;
      padding: 0.1em;
    }

    .class-filter.all .all,
    .class-filter.mutual .mutual,
    .class-filter.target .target,
    .class-filter.leeche .leeche {
      border: 1px solid red;
    }

    .label-filter a {
        background-color: #ddd;
        border-radius: 3px;
        padding: 0.1em;
    }

    .label-filter a.yes {
      border: 1px solid blue;
    }

    .class-filter .all::before,
    .class-filter .mutual::before,
    .class-filter .target::before,
    .class-filter .leeche::before,
    .label-filter a::before {
      content: '☐ '
    }

    .class-filter.all .all::before,
    .class-filter.mutual .mutual::before,
    .class-filter.target .target::before,
    .class-filter.leeche .leeche::before,
    .label-filter a.yes::before {
      content: '☒ '
    }

    table#seer tr td:nth-child(2) {
      padding: 0 0.5em;
    }

    .sigil {
      display: inline-block;
      vertical-align: middle;
      margin: 0 0.5em 0 0;
      padding: 0.2em;
      border-radius: 0.2em;
    }

    .sigil * {
      margin: 0;
      padding: 0;
    }

    .label {
      display: inline-block;
      background-color: #ccc;
      border-radius: 3px;
      margin-right: 0.5em;
      padding: 0.1em;
    }
    .label input[type="text"] {
      max-width: 100px;
    }
    .label span {
      margin: 0 0 0 0.2em;
    }

    button {
      padding: 0.2em 0.5em;
    }
    '''
  ::
  ++  page
    ^-  manx
    ;html
      ;head
        ;title:"%seer"
        ;meta(charset "utf-8");
        ;meta(name "viewport", content "width=device-width, initial-scale=1");
        ;style:"{(trip style)}"
      ==
      ;body(onload "odor()")
        ;h2:"crop duster"

        ;p.seer-box(onclick "document.getElementById('poem').style.display='block'")
          ;+  =/  url  =;  param   `tape`['/' 'f' 'a' 'r' 't' param]
            `tape`['?' 't' 'o' 'g' '=' (trip toggled)]
          ;a.toggled/"{url}":"O"
          ;t:"Foul Room, thou Stench-filled Hold..."

        ==
        ;+  ;p.seer-box
          =id  "poem"
          =onclick  "this.style.display='none'"
          =style  "display: {(trip tog)}"
          ;+  ;/  %-  trip
          '''
          Where Farts doth Echo, young and old,
          How doth thy Reek assail my Nose,
          And cloud my Senses, till I doze.

          What Evil Spirit doth reside
          In thy Confines, thus to deride
          The Sense of Smell, with such a Fume?
          An offence unto the very room.

          But though thy Miasma doth assail,
          I'll not be held within thy Jail.
          I'll brave thy Foul and noisome Air,
          And seek the Fresher Atmosphere.

          So Fare thee well, O Room of Farts,
          I'll leave thy Stench and all thy Arts.
          To those who find thy Reek delight,
          But I'll seek Scents that are more Right.
          '''
        ==
        ;+  ?~  msg  ;p:""

            ?:  o.u.msg  ::TODO  lightly refactor
              ;p.green:"{(trip t.u.msg)}"
            ;p.red:"{(trip t.u.msg)}"

        ;+  class-selectors
        ;+  label-selectors

        ;table#seer
          ;form(method "post")
            ;tr(style "font-weight: bold")
              ;td:""
              ;td:""
              ;td:"prey"
              ;td:"brand"
            ==
            ;tr
              ;td:""
              ;td
                ;button(type "submit", name "what", value "dust"):"dust"
              ==
              ;td
                ;input(type "text", name "who", placeholder "~smellt-deltyt");
              ==
              ;td.label
                ;input(type "text", name "lists", placeholder "beefy, loud");
              ==
            ==
          ==
          ;*  ?:(|(=(%all rel) =(%mutual rel)) (peers %mutual mutuals) ~)
          ;*  ?:(|(=(%all rel) =(%target rel)) (peers %target targets) ~)
          ;*  ?:(|(=(%all rel) =(%leeche rel)) (peers %leeche leeches) ~)
        ==

        ;h3:"get 'em"

        ;table#pals
          ;*  ?:(=(%all rel) fresh ~)
        ==
        ;br;
        ;br;

        ;h5(align "center"):"breaking wind, decentralized"
        ;script:"{(trip odor)}"
      ==
    ==
  ++  pals-installed  ~+
    .^(? %gu /(scot %p our.bowl)/pals/(scot %da now.bowl))
  ::
  ++  fresh
    ^-  (list manx)
    ?.  pals-installed
        ;+  ;p:"%pals not installed"
    =;  render
      ?~  render
        ;+  ;div.seer-box
          ;p.seer-box:"{(trip poem)}"
        ==
      render
    %+  murn  ~(tap in pals)
    |=  =ship
    ^-  (unit manx)
    ?:  =(ship our.bowl)  ~
    ?:  (~(has by outgoing) ship)
      ~
    `(render-pal ship)
  ::
  ++  poem
    '''
    Thy Reek hath assailed all and sundry...
    '''
  ++  render-pal
    |=  =ship
    ^-  manx
    ;tr
      ;td
        ;+  (pals-adder ship)
      ==
      ;td
        ;+  (sigil ship)
        ; {(scow %p ship)}
      ==
    ==
  ::
  ++  slur
    |=  [rel=role tag=(set @ta)]
    ^-  tape
    =-  ['/' 'f' 'a' 'r' 't' -]
    |^  ^-  tape
        ?-  [rel tag]
          [%all ~]  ""
          [* ~]     ['?' 'r' 'e' 'l' '=' (trip rel)]
          [%all *]  ['?' 't' 'a' 'g' '=' tags]
          [* *]     (weld $(tag ~) '&' 't' 'a' 'g' '=' tags)
        ==
    ++  tags  =>  [tag=tag ..zuse]  ~+
              (zing (join "&tag=" (turn ~(tap in tag) trip)))
    --
  ::
  ++  class-selectors
    ^-  manx
    =/  m  (lent mutuals)
    =/  t  (lent targets)
    =/  l  (lent leeches)
    ;div(class "class-filter {(trip rel)}")
      ; funk:
      ;a.all/"{(slur %all tag)}":"all ({(scow %ud :(add m t l))})"
      ;a.mutual/"{(slur %mutual tag)}":"dusting ({(scow %ud m)})"
      ;a.target/"{(slur %target tag)}":"dusted ({(scow %ud t)})"
      ;a.leeche/"{(slur %leeche tag)}":"dusters ({(scow %ud l)})"
    ==
  ::
  ++  label-selectors
    ^-  manx
    ;div.label-filter  ; reek:
      ;*
      %+  turn
        =-  (sort - aor)
        %~  tap   by
        %+  roll  ~(val by outgoing)
        |=  [l=(set @ta) a=(map @ta @ud)]
        =/  l=(list @ta)  ~(tap in l)
        |-
        ?~  l  a
        $(l t.l, a (~(put by a) i.l +((~(gut by a) i.l 0))))
      |=  [l=@ta n=@ud]
      =/  hav  (~(has in tag) l)
      =.  tag  (?:(hav ~(del in tag) ~(put in tag)) l)
      =/  l  (trip l)
      ?.  hav
        ;a/"{(slur rel tag)}":"{l} ({(scow %ud n)})"
      ;a.yes/"{(slur rel tag)}":"{l} ({(scow %ud n)})"
    ==
  ::
  ++  list-label
    |=  =ship
    |=  name=@ta
    ^-  manx
    ;form.label(method "post")
      ;span:"{(trip name)}"
      ;input(type "hidden", name "who", value "{(scow %p ship)}");
      ;input(type "hidden", name "lists", value "{(trip name)}");
      ;button(type "submit", name "what", value "unlist"):"puff"
    ==
  ::
  ++  list-adder
    |=  =ship
    ^-  manx
    ;form.label(method "post")
      ;input(type "text", name "lists", placeholder "swampy");
      ;input(type "hidden", name "who", value "{(scow %p ship)}");
      ;input(type "hidden", name "what", value "enlist");
    ==
  ::
  ++  friend-adder
    |=  =ship
    ^-  manx
    ;form(method "post")
      ;input(type "hidden", name "who", value "{(scow %p ship)}");
      ;button(type "submit", name "what", value "dust"):"fume"
    ==
  ::
  ++  pals-adder
    |=  =ship
    ^-  manx
    ;form(method "post")
      ;input(type "hidden", name "who", value "{(scow %p ship)}");
      ;button(type "submit", name "what", value "dust"):"dust"
    ==
  ::
  ++  friend-remover
    |=  =ship
    ^-  manx
    ;form(method "post")
      ;input(type "hidden", name "who", value "{(scow %p ship)}");
      ;button(type "submit", name "what", value "wipe"):"wipe"
    ==
  ::
  ++  peers
    ::TODO  maybe take acks in pez and do sorting internally?
    |=  [kind=?(%leeche %mutual %target) pez=(list [ship (set @ta)])]
    ^-  (list manx)
    %+  turn  pez
    |=  [=ship lists=(set @ta)]
    ^-  manx
    =/  ack=(unit ?)  (~(get by receipts) ship)
    ;tr
      ;td
        ;+  (status kind ack)
      ==
      ;+  ?:  ?=(%leeche kind)
            ;td
              ;+  (friend-adder ship)
            ==
          ;td
            ;+  (friend-remover ship)
          ==
      ;td
        ;+  (sigil ship)
        ; {(scow %p ship)}
      ==
      ;+  ?:  ?=(%leeche kind)  ;td;
          ;td
            ;+  (list-adder ship)
            ;*  (turn (sort ~(tap in lists) aor) (list-label ship))
          ==
    ==
  ::
  ++  mutuals  ~+
    %+  skim  (sort ~(tap by outgoing) dor)
    |=  [=ship les=(set @ta)]
    ?&  (~(has in incoming) ship)
    ?|  =(~ tag)
        (~(any in les) ~(has in tag))
    ==  ==
  ::
  ++  pals  ~+
    .^((set ship) %gx /(scot %p our.bowl)/pals/(scot %da now.bowl)/mutuals/noun)
  ::
  ++  targets  ~+
    %+  sort
      %+  skim  ~(tap by outgoing)
      |=  [=ship les=(set @ta)]
      ?&  !(~(has in incoming) ship)
      ?|  =(~ tag)
          (~(any in les) ~(has in tag))
      ==  ==
    |=  [[sa=ship ma=*] [sb=ship mb=*]]
    =+  a=(~(get by receipts) sa)
    =+  b=(~(get by receipts) sb)
    ?:  =(a b)  (dor ma mb)
    ?~(a ?=(~ b) ?~(b & |(u.a !u.b)))
  ::
  ++  leeches  ~+
    ?.  =(~ tag)  ~
    %+  murn  (sort ~(tap in incoming) dor)
    |=  =ship
    ?:  (~(has by outgoing) ship)  ~
    (some ship ~)
  ::
  ++  contacts  ~+
    =/  base=path
      /(scot %p our.bowl)/contact-store/(scot %da now.bowl)
    ?.  .^(? %gu base)  *rolodex:contact
    .^(rolodex:contact %gx (weld base /all/noun))
  ::
  ++  sigil
    |=  =ship
    ^-  manx
    =/  bg=@ux
      ?~(p=(~(get by contacts) ship) 0xff.ffff color.u.p)
    =/  fg=tape
      ::TODO  move into sigil.hoon or elsewhere?
      =+  avg=(div (roll (rip 3 bg) add) 3)
      ?:((gth avg 0xc1) "black" "white")
    =/  bg=tape
      ((x-co:co 6) bg)
    ;div.sigil(style "background-color: #{bg}; width: 20px; height: 20px;")
      ;img@"/seer/sigil.svg?p={(scow %p ship)}&fg={fg}&bg=%23{bg}&icon&size=20";
    ==
  ::
  ++  odor
    '''
    var odor = (function () {
    var mp3 = {
      prefix: "data:audio/mp3;base64,",
      sound: [
          "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",
        ]
    };

    return function(fun) {
    function playAudio(position){
      var player = getPlayer()
        , audio = getAudioFor(player)
        , rand = Math.floor(Math.random() * audio.sound.length);

      player.src = audio.prefix + audio.sound[position || rand];
      player.play();
    };

    function getAudioFor(player){
      return mp3;
    }

    function getPlayer() {
      var container = getContainer(), player
        , players = container.getElementsByTagName("audio");

      for (player in  players) {
        if (player.currentTime === 0 || player.ended) {
          return player;
        }
      }

      player = document.createElement("audio");
      container.appendChild(player);
      return player;
    };

    function getContainer() {
      var container = document.getElementById("odor");

      if (container === null) {
        container = document.createElement("div");
        container.id = "odor";
        document.getElementsByTagName('body')[0].appendChild(container);
      }

      return container;
    }
    playAudio()
    }
    })();
    '''
  ::
  ++  status
    |=  [kind=?(%leeche %mutual %target) ack=(unit ?)]
    =.  ack
      ?.  ?=(%target kind)  ~
      `(fall ack |)
    ^-  manx  ~+
    ?-  kind
        %leeche
      ;div
        ;+  %-  need  %-  de-xml:html
        '<svg width="25px" height="25px" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg" fill="#000000"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"><path fill="#000000" d="M364.563 27.5c-24.54 10.796-66.057 18.094-113.875 18.094-47.3 0-89.258-6.898-113.907-17.5C107.477 64.73 97.12 118.44 107 177c10.73 63.596 50.354 119.6 85.688 155.78 17.285-4.952 36.943-7.717 57.843-7.717 20.725 0 40.228 2.72 57.407 7.593 35.5-36.38 75.654-92.59 86.407-155.656 10.04-58.882-.233-112.842-29.78-149.5zm-187.625 80.03c10.768.263 21.255 4.955 29.937 12.282 11.577 9.77 20.607 24.33 25.25 41.657 4.643 17.326 4.078 34.437-1.063 48.686-5.14 14.25-15.398 26.053-29.78 29.906-14.384 3.854-29.174-1.23-40.75-11-11.577-9.77-20.608-24.328-25.25-41.656-4.644-17.327-4.08-34.47 1.062-48.72 5.14-14.248 15.398-26.02 29.78-29.874 3.597-.963 7.224-1.368 10.814-1.28zm146.75 0c3.59-.086 7.216.32 10.812 1.282 14.383 3.854 24.64 15.626 29.78 29.876 5.142 14.25 5.707 31.39 1.064 48.718-4.643 17.328-13.674 31.887-25.25 41.656-11.577 9.77-26.367 14.854-40.75 11-14.383-3.853-24.64-15.657-29.78-29.906-5.142-14.25-5.707-31.36-1.064-48.687 4.643-17.33 13.673-31.888 25.25-41.657 8.682-7.328 19.17-12.02 29.938-12.282zm-148.47 18.657c-1.44.063-2.867.286-4.25.657-7.374 1.976-13.434 8.13-17.062 18.187-3.628 10.058-4.295 23.6-.562 37.532 3.733 13.933 11.08 25.324 19.25 32.22 8.17 6.894 16.47 9.194 23.844 7.218 4.996-1.34 9.37-4.6 12.812-9.688-.557.206-1.108.376-1.688.532-14.782 3.96-31.402-10.042-37.093-31.28-5.692-21.24 1.685-41.665 16.468-45.626 3.214-.862 6.526-.853 9.78-.125-.63-.595-1.265-1.178-1.905-1.72-6.128-5.17-12.326-7.766-18.157-7.905-.486-.012-.957-.02-1.437 0zm148.75 0c-5.83.14-12.028 2.736-18.156 7.907-8.17 6.895-15.516 18.255-19.25 32.187-3.733 13.934-3.065 27.476.563 37.532 3.628 10.057 9.657 16.212 17.03 18.188 7.376 1.976 15.706-.324 23.876-7.22.87-.732 1.748-1.51 2.595-2.343-3.923 1.263-7.97 1.453-11.875.407-14.783-3.96-22.13-24.386-16.438-45.625 5.692-21.24 22.28-35.244 37.063-31.282 1.253.335 2.45.812 3.594 1.375-3.514-5.533-8.07-9.064-13.314-10.47-1.843-.493-3.744-.702-5.687-.656zm-73.437 217.594c-30.047 0-57.177 6.322-76 15.94-18.82 9.616-28.155 21.615-28.155 32.686 0 2.838.615 5.752 1.844 8.656 5.233-4.285 11.252-8.117 17.81-11.468 22.253-11.37 51.873-18 84.5-18 32.63 0 62.25 6.63 84.5 18 6.547 3.344 12.56 7.163 17.783 11.437 1.22-2.894 1.843-5.794 1.843-8.624 0-11.07-9.334-23.07-28.156-32.687-18.822-9.618-45.92-15.94-75.97-15.94zm0 46.5c-30.047 0-57.177 6.322-76 15.94-18.82 9.616-28.155 21.615-28.155 32.686 0 11.07 9.334 23.07 28.156 32.688 18.823 9.617 45.953 15.97 76 15.97 30.05-.002 57.148-6.353 75.97-15.97 18.822-9.617 28.156-21.617 28.156-32.688 0-11.07-9.334-23.07-28.156-32.687-18.822-9.618-45.92-15.94-75.97-15.94zm0 28.19c15.2 0 28.952 2.186 39.75 6.186 5.4 2 10.118 4.412 14 7.813 3.884 3.4 7.25 8.417 7.25 14.467 0 6.05-3.366 11.07-7.25 14.47-3.882 3.4-8.6 5.812-14 7.812-10.798 4-24.55 6.186-39.75 6.186-15.197 0-28.98-2.187-39.78-6.187-5.4-2-10.086-4.413-13.97-7.814-3.882-3.4-7.25-8.418-7.25-14.47 0-6.05 3.368-11.067 7.25-14.467 3.884-3.402 8.57-5.814 13.97-7.814 10.8-4 24.583-6.187 39.78-6.187zm0 18.686c-13.327 0-25.384 2.107-33.28 5.03-3.948 1.464-6.812 3.168-8.156 4.345-.292.256-.263.258-.406.408.143.15.114.15.406.406 1.344 1.177 4.208 2.913 8.156 4.375 7.896 2.923 19.953 5 33.28 5 13.33 0 25.387-2.077 33.282-5 3.948-1.463 6.812-3.2 8.157-4.376.29-.255.26-.257.405-.406-.144-.15-.115-.152-.406-.407-1.346-1.176-4.21-2.88-8.158-4.342-7.895-2.925-19.953-5.032-33.28-5.032z"></path></g></svg>'
      ==
    ::
        %mutual
      ;div
        ;+  %-  need  %-  de-xml:html
        '<svg fill="#000000" height="25px" width="25px" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 496.169 496.169" xml:space="preserve"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <g transform="translate(2 1)"> <g> <g> <path d="M467.574,103.33c-1.576-25.323-21.939-44.678-47.733-44.678H73.192c-25.761,0-46.104,19.307-47.726,44.582 c-58.982,89.638-5.81,181.493,2.401,194.631l24.341,130.098c0.839,4.197,4.197,6.715,8.393,6.715c0.839,0,0.839,0,1.679,0.839 c4.197-0.839,7.554-5.875,6.715-10.072L43.815,291.99l-0.839-1.679c-0.799-0.799-56.427-83.845-10.205-167.894l8.526-12.565 c5.228-0.523,16.155-1.534,30.32-1.537c30.155,0.019,74.335,4.54,109.865,27.502c1.694,1.095,3.369,2.232,5.021,3.412 c27.679,20.969,45.299,50.32,51.187,89.728c-0.278,39.164-22.031,75.736-56.223,93.25c-4.197,1.679-5.875,6.715-3.357,10.911 c1.679,2.518,4.197,4.197,7.554,4.197c1.679,0,2.518-0.839,3.357-0.839c20.407-10.42,37.205-26.914,48.682-46.674v137.323 c0,5.036,3.357,8.393,8.393,8.393c2.758,0,5.007-1.012,6.483-2.75c1.738-1.475,2.75-3.724,2.75-6.482V291.95 c11.222,18.809,27.339,34.483,47.003,44.525c1.679,0.839,2.518,0.839,4.197,0.839c3.357,0,5.875-1.679,6.715-4.197 c2.518-3.357,0.839-8.393-3.357-10.911c-28.853-14.778-48.847-43.129-54.557-75.154v-18.852 c5.875-38.61,23.502-68.826,51.2-88.97c36.205-25.861,83.031-30.866,114.351-30.913c14.016,0.018,24.826,1.017,30.016,1.536 c0,0.839,0.839,0.839,0.839,1.679l10.16,15.507c41.907,82.062-10.323,159.35-12.678,163.274l-0.839,1.679l-25.18,132.616 c-0.839,5.036,2.518,9.233,6.715,10.072c0.839,0,0.839,0,1.679,0c3.357,0,6.715-2.518,7.554-7.554l24.341-129.259 C471.695,284.732,525.635,192.938,467.574,103.33z M73.192,75.439h347.488c11.553,0,22.281,7.308,27.425,17.125 c-12.588-1.263-35.282-2.498-61.315,0.659c-28.985,3.226-62.192,11.911-90.334,32.577 c-23.502,16.787-40.289,39.449-50.361,67.148c-7.866-21.631-19.846-40.173-35.902-55.262c-0.282-0.267-0.566-0.534-0.851-0.799 c-0.575-0.531-1.149-1.062-1.734-1.584c-2.364-2.123-4.816-4.164-7.351-6.13c-0.13-0.101-0.26-0.202-0.391-0.302 c-1.356-1.043-2.727-2.073-4.132-3.071c-18.075-13.075-38.263-21.383-58.063-26.559c-0.339-0.089-0.677-0.182-1.016-0.269 c-0.364-0.093-0.727-0.182-1.09-0.274c-37.041-9.365-72.301-7.92-89.752-6.229C50.948,82.7,60.855,75.439,73.192,75.439z"></path> <path d="M434.95,218.127c0-5.036-0.839-7.554-1.679-9.233c-5.036-12.59-18.466-19.305-31.056-15.948 c-5.875,1.679-10.072,5.036-13.43,9.233c-5.036-2.518-10.911-2.518-15.948-0.839c-12.59,3.357-19.305,16.787-16.787,30.216 c0,0.839,0.839,4.197,3.357,8.393c3.357,5.875,9.233,10.911,15.948,14.269l26.859,11.751c3.357,0.839,6.715,0.839,7.554,0.839 c0.839-0.839,1.679-0.839,3.357-2.518l15.948-25.18C433.271,232.396,434.95,225.681,434.95,218.127z M413.127,228.199 l-11.751,19.305l-20.144-9.233c-3.357-1.679-6.715-4.197-8.393-7.554c-0.839-1.679-0.839-2.518-0.839-2.518 c-0.839-5.036,0.839-10.072,3.357-12.59c3.357-0.839,5.875,0,8.393,2.518c2.518,2.518,5.875,3.357,9.233,2.518 c3.357-0.839,5.875-3.357,5.875-6.715c0.839-3.357,2.518-5.875,5.875-6.715c5.036-1.679,9.233,2.518,10.911,6.715 c0,0,0.839,1.679,0.839,3.357C416.484,220.645,415.645,224.842,413.127,228.199z"></path> </g> </g> </g> </g></svg>'
      ==
    ::
        %target
      ;div
        ;+  ?.  =([~ &] ack)
            %-  need  %-  de-xml:html
            '<svg fill="#000000" height="25px" width="25px" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 167.593 167.593" xml:space="preserve"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <g> <g> <g> <path d="M164.027,101.626H16.173c-4.985,0-9.041-4.799-9.041-10.697c0-5.898,4.057-10.697,9.041-10.697 c1.969,0,3.566-1.597,3.566-3.566S18.142,73.1,16.173,73.1C7.255,73.099,0,81.098,0,90.928c0,8.466,5.393,15.541,12.582,17.351 c0.508,0.278,1.061,0.478,1.681,0.478h149.764c1.969,0,3.566-1.597,3.566-3.566S165.996,101.626,164.027,101.626z"></path> <path d="M85.579,58.836c15.729,0,28.526-12.797,28.526-28.526S101.309,1.783,85.579,1.783c-15.73,0-28.526,12.797-28.526,28.526 S69.85,58.836,85.579,58.836z M64.507,26.744C66.212,16.641,74.999,8.915,85.579,8.915c11.798,0,21.395,9.597,21.395,21.395 s-9.597,21.395-21.395,21.395c-10.58,0-19.367-7.727-21.073-17.829h24.639v-7.132H64.507z"></path> <path d="M142.77,123.02c1.969,0,3.566-1.597,3.566-3.566s-1.597-3.566-3.566-3.566H96.277c-1.969,0-3.566,1.597-3.566,3.566 s1.597,3.566,3.566,3.566H142.77z"></path> <path d="M32.092,94.494h106.974c1.969,0,3.566-1.597,3.566-3.566s-1.597-3.566-3.566-3.566H32.092 c-1.969,0-3.566,1.597-3.566,3.566S30.123,94.494,32.092,94.494z"></path> <path d="M151.547,130.152H49.921c-0.62,0-1.173,0.2-1.681,0.478c-7.19,1.81-12.582,8.886-12.582,17.351 c0,9.83,7.255,17.829,16.173,17.829c1.969,0,3.566-1.597,3.566-3.566s-1.597-3.566-3.566-3.566 c-4.985,0-9.041-4.799-9.041-10.697c0-5.899,4.057-10.697,9.041-10.697h99.716c1.969,0,3.566-1.597,3.566-3.566 S153.516,130.152,151.547,130.152z"></path> <path d="M110.54,144.415H57.053c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566h53.487 c1.969,0,3.566-1.597,3.566-3.566S112.509,144.415,110.54,144.415z"></path> <path d="M26.871,144.415c-4.985,0-9.041-4.798-9.041-10.697c0-5.899,4.057-10.697,9.041-10.697h44.583 c1.969,0,3.566-1.597,3.566-3.566c0-1.969-1.597-3.566-3.566-3.566H24.961c-0.62,0-1.173,0.2-1.681,0.478 c-7.19,1.81-12.582,8.886-12.582,17.351c0,9.83,7.255,17.829,16.173,17.829c1.969,0,3.566-1.597,3.566-3.566 S28.84,144.415,26.871,144.415z"></path> </g> </g> </g> </g></svg>'
        %-  need  %-  de-xml:html
        '<svg fill="#000000" height="25px" width="25px" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 178.29 178.29" xml:space="preserve"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <g> <g> <g> <path d="M78.447,57.053c15.729,0,28.526-12.797,28.526-28.526S94.176,0,78.447,0S49.921,12.797,49.921,28.526 S62.718,57.053,78.447,57.053z M78.447,7.132c10.58,0,19.367,7.727,21.073,17.829H74.882v7.132H99.52 c-1.706,10.102-10.492,17.829-21.073,17.829c-11.798,0-21.395-9.597-21.395-21.395C57.052,16.729,66.65,7.132,78.447,7.132z"></path> <path d="M139.066,121.237c1.969,0,3.566-1.597,3.566-3.566c0-1.969-1.597-3.566-3.566-3.566H92.572 c-1.969,0-3.566,1.597-3.566,3.566c0,1.969,1.597,3.566,3.566,3.566H139.066z"></path> <path d="M71.315,117.672c0-1.969-1.597-3.566-3.566-3.566H21.257c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566 h46.493C69.718,121.237,71.315,119.641,71.315,117.672z"></path> <path d="M24.96,92.711h106.974c1.969,0,3.566-1.597,3.566-3.566c0-1.969-1.597-3.566-3.566-3.566H24.96 c-1.969,0-3.566,1.597-3.566,3.566C21.395,91.114,22.991,92.711,24.96,92.711z"></path> <path d="M147.853,128.369c-0.293,0-0.555,0.1-0.828,0.167c-0.273-0.067-0.535-0.167-0.828-0.167H44.572 c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566h101.626c0.293,0,0.555-0.1,0.828-0.167 c0.273,0.067,0.534,0.167,0.828,0.167c4.985,0,9.041,4.799,9.041,10.697c0,5.899-4.057,10.697-9.041,10.697 c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566c8.918,0,16.173-7.999,16.173-17.829 C164.026,136.368,156.772,128.369,147.853,128.369z"></path> <path d="M105.064,142.632c-0.293,0-0.555,0.1-0.828,0.167c-0.273-0.067-0.535-0.167-0.828-0.167H49.921 c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566h53.487c0.293,0,0.555-0.1,0.828-0.167 c0.273,0.067,0.534,0.167,0.828,0.167c4.985,0,9.041,4.798,9.041,10.697s-4.057,10.697-9.041,10.697 c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566c8.918,0,16.173-7.999,16.173-17.829S113.981,142.632,105.064,142.632 z"></path> <path d="M158.551,71.316c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566c4.985,0,9.041,4.799,9.041,10.697 c0,5.898-4.057,10.697-9.041,10.697c-0.293,0-0.555,0.1-0.828,0.167c-0.273-0.067-0.535-0.167-0.828-0.167H7.132 c-1.969,0-3.566,1.597-3.566,3.566s1.597,3.566,3.566,3.566h149.764c0.293,0,0.555-0.1,0.828-0.167 c0.273,0.067,0.534,0.167,0.828,0.167c8.918,0,16.173-7.999,16.173-17.829C174.725,79.315,167.468,71.316,158.551,71.316z"></path> </g> </g> </g> </g></svg>'
      ==
    ==
  --
--
