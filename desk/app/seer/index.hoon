|=  inject=json
^-  manx
;html
::
  ;head
    ;title: %seer
    ;meta(charset "utf-8");
    ;meta
      =name     "viewport"
      =content  "width=device-width, initial-scale=1, shrink-to-fit=no";
    ;link(rel "stylesheet", href "/apps/seer/index.css");
    ;link(rel "icon", type "image/png", href "/apps/landscape/favicon.png");

    ;script@"/session.js";
    ;script: window.injectedState = {(en-json:html inject)}
  ==
::
  ;body
    ;div#root;
    ;script@"/apps/seer/index.js";
  ==
==
