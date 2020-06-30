|=  inject=json
^-  manx
;html
::
  ;head
    ;title: Srrs
    ;meta(charset "utf-8");
    ;meta
      =name     "viewport"
      =content  "width=device-width, initial-scale=1, shrink-to-fit=no";
    ;link(rel "stylesheet", href "/~srrs-files/css/index.css");
    ;link(rel "icon", type "image/png", href "/~launch/img/Favicon.png");
    ;script@"/~landscape/js/channel.js";
    ;script@"/~landscape/js/session.js";
    ;script: window.injectedState = {(en-json:html inject)}
  ==
::
  ;body
    ;div#root;
    ;script@"/~srrs-files/js/index.js";
  ==
==
