::  outbound request discipline for %seer: destination policy, iris cards,
::  bounded bodies, server-sent events, html extraction, and the provider
::  wire formats. everything here is pure; the agent owns state and wires.
::
/-  *seer
|%
+$  target  [secure=? host=@t port=(unit @ud) path=@t]
+$  provider-result
  $:  text=(unit @t)
      usage=(unit @ud)
      completed=?
      refusal=?
      tool-call=?
      error=(unit @t)
  ==
::
++  codex-oauth-url    'https://chatgpt.com/backend-api/codex/responses'
++  codex-api-url      'https://api.openai.com/v1/responses'
++  codex-catalog-oauth  'https://chatgpt.com/backend-api/codex/models?client_version=0.151.0'
++  codex-catalog-api    'https://api.openai.com/v1/models'
++  claude-messages-url  'https://api.anthropic.com/v1/messages'
++  claude-catalog-url   'https://api.anthropic.com/v1/models?limit=100'
++  codex-user-agent   'codex_cli_rs/0.151.0'
++  claude-user-agent  'claude-cli/2.1.257 (external, cli)'
::
++  lower
  |=  text=@t
  ^-  @t
  (crip (cass (trip text)))
::
::  +destination-error: why a locator may not be fetched. the runtime
::  resolves names, so this is a hostname policy, not a network policy.
::
++  destination-error
  |=  url=@t
  ^-  (unit @tas)
  ?:  (gth (met 3 url) 4.096)  `%url-too-long
  =/  parsed  (parse-target url)
  ?~  parsed  `%invalid-url
  =/  host  host.u.parsed
  ?:  =('' host)  `%invalid-url
  =/  parts=(list @t)  (labels host)
  ?:  =(~ parts)  `%invalid-url
  ?:  =(1 (lent parts))  `%private-host
  ?:  (lien parts |=(label=@t =('' label)))  `%invalid-url
  =/  last  (rear parts)
  ?:  (~(has in (silt ~['localhost' 'local' 'internal' 'onion' 'home' 'lan' 'localdomain' 'arpa'])) last)
    `%private-host
  ?:  =('localhost' (snag 0 parts))  `%private-host
  ?:  (levy parts |=(label=@t (levy (trip label) |=(ch=@ &((gte ch '0') (lte ch '9'))))))
    `%ip-literal
  ?^  port.u.parsed
    ?.  ?|(=(80 u.port.u.parsed) =(443 u.port.u.parsed))  `%port-not-allowed
    ~
  ~
::
++  labels
  |=  host=@t
  ^-  (list @t)
  (rash (lower host) (more dot (cook crip (star ;~(less dot next)))))
::
::  +parse-target: scheme, host, optional port, and the request path with
::  its query. userinfo, ipv6 brackets, and other schemes fail to parse.
::
++  parse-target
  |=  url=@t
  ^-  (unit target)
  =/  text  (trip url)
  =/  secure=(unit ?)
    ?:  =("https://" (scag 8 text))  `%.y
    ?:  =("http://" (scag 7 text))  `%.n
    ~
  ?~  secure  ~
  =/  rest  (slag ?:(u.secure 8 7) text)
  =/  authority  (scag (fall (find "/" rest) (lent rest)) rest)
  =/  path  (slag (lent authority) rest)
  =?  path  ?&(=(~ path) !=(~ (find "?" authority)))
    (weld "/" (slag (fall (find "?" authority) 0) authority))
  =.  authority  (scag (fall (find "?" authority) (lent authority)) authority)
  ?:  |(?=(~ authority) !=(~ (find "@" authority)) !=(~ (find "[" authority)))  ~
  =/  parsed-authority=(unit [host=@t port=(unit @ud)])
    %+  rush  (crip authority)
    ;~(plug (cook crip (star ;~(less col next))) (punt ;~(pfix col dem)))
  ?~  parsed-authority  ~
  =/  host=tape  (trip host.u.parsed-authority)
  =/  port=(unit @ud)  port.u.parsed-authority
  ?.  (levy host |=(ch=@ ?|(&((gte ch 'a') (lte ch 'z')) &((gte ch 'A') (lte ch 'Z')) &((gte ch '0') (lte ch '9')) =(ch '-') =(ch '.'))))
    ~
  `[u.secure (lower (crip host)) port (crip ?~(path "/" path))]
::
::  +resolve-redirect: an absolute location is checked again; a root
::  relative location inherits the origin. anything else is rejected.
::
++  resolve-redirect
  |=  [base=@t location=@t]
  ^-  (unit @t)
  ?:  |(=('' location) (gth (met 3 location) 4.096))  ~
  =/  text  (trip location)
  ?:  ?|(=("https://" (scag 8 text)) =("http://" (scag 7 text)))  `location
  ?:  =(~ text)  ~
  ?.  =('/' (snag 0 text))  ~
  =/  parsed  (parse-target base)
  ?~  parsed  ~
  =/  origin=tape
    ;:  weld
      ?:(secure.u.parsed "https://" "http://")
      (trip host.u.parsed)
      ?~(port.u.parsed "" (weld ":" (a-co:co u.port.u.parsed)))
    ==
  `(crip (weld origin text))
::
++  header
  |=  [headers=header-list:http name=@t]
  ^-  (unit @t)
  =/  wanted  (lower name)
  |-
  ?~  headers  ~
  ?:  =(wanted (lower key.i.headers))  `value.i.headers
  $(headers t.headers)
::
++  content-type
  |=  headers=header-list:http
  ^-  @t
  (lower (fall (header headers 'content-type') ''))
::
++  is-html
  |=  headers=header-list:http
  ^-  ?
  =/  kind  (trip (content-type headers))
  ?|  !=(~ (find "text/html" kind))
      !=(~ (find "application/xhtml" kind))
      !=(~ (find "text/xml" kind))
      !=(~ (find "application/xml" kind))
  ==
::
++  request
  |=  [method=?(%'GET' %'POST') url=@t headers=header-list:http body=(unit @t)]
  ^-  request:http
  :*  method
      url
      headers
      ?~(body ~ `(as-octs:mimes:html u.body))
  ==
::
++  iris-card
  |=  [=wire req=request:http]
  ^-  card:agent:gall
  [%pass wire %arvo %i %request req [0 0]]
::
++  cancel-card
  |=  =wire
  ^-  card:agent:gall
  [%pass wire %arvo %i %cancel-request ~]
::
++  wait-card
  |=  [=wire at=@da]
  ^-  card:agent:gall
  [%pass wire %arvo %b %wait at]
::
++  body-text
  |=  file=(unit mime-data:iris)
  ^-  @t
  ?~  file  ''
  q.data.u.file
::
::  json helpers over a decoded object
::
++  get
  |=  [jon=json key=@t]
  ^-  (unit json)
  ?.  ?=([%o *] jon)  ~
  (~(get by p.jon) key)
::
++  get-string
  |=  [jon=json key=@t]
  ^-  (unit @t)
  =/  value  (get jon key)
  ?~  value  ~
  ?.  ?=([%s *] u.value)  ~
  `p.u.value
::
++  get-number
  |=  [jon=json key=@t]
  ^-  (unit @ud)
  =/  value  (get jon key)
  ?~  value  ~
  ?.  ?=([%n *] u.value)  ~
  (rush p.u.value dem)
::
++  get-array
  |=  [jon=json key=@t]
  ^-  (list json)
  =/  value  (get jon key)
  ?~  value  ~
  ?.  ?=([%a *] u.value)  ~
  p.u.value
::
++  get-bool
  |=  [jon=json key=@t]
  ^-  (unit ?)
  =/  value  (get jon key)
  ?~  value  ~
  ?.  ?=([%b *] u.value)  ~
  `p.u.value
::
++  string-or
  |=  [jon=json key=@t fallback=@t]
  ^-  @t
  (fall (get-string jon key) fallback)
::
++  decode
  |=  text=@t
  ^-  (unit json)
  =/  parsed  (mole |.((de:json:html text)))
  ?~  parsed  ~
  u.parsed
::
::  +provider-json: the first json object in a model reply, tolerating
::  markdown fences and prose around it. a reply with no object is not
::  an answer.
::
++  provider-json
  |=  text=@t
  ^-  (unit json)
  =/  direct  (decode text)
  ?:  ?&(?=(^ direct) ?=([%o *] u.direct))  direct
  =/  tap  (trip text)
  =/  start  (find "\{" tap)
  ?~  start  ~
  =/  end  (find "}" (flop tap))
  ?~  end  ~
  =/  stop  (sub (lent tap) u.end)
  ?.  (gth stop u.start)  ~
  =/  inner  (crip (scag (sub stop u.start) (slag u.start tap)))
  =/  parsed  (decode inner)
  ?~  parsed  ~
  ?.  ?=([%o *] u.parsed)  ~
  parsed
::
::  server-sent events: every data payload that decodes as json, in order.
::
++  sse-events
  |=  raw=@t
  ^-  (list json)
  =/  lines  (to-wain:format raw)
  =/  out=(list json)  ~
  =/  buffer=(list @t)  ~
  |-
  ?~  lines
    =/  last  (flush-event buffer)
    (flop ?~(last out [u.last out]))
  =/  line  (strip-cr i.lines)
  ?:  =('' line)
    =/  event  (flush-event buffer)
    $(lines t.lines, buffer ~, out ?~(event out [u.event out]))
  ?:  =('data:' (end [3 5] line))
    =/  payload  (rsh [3 5] line)
    =?  payload  =(' ' (end [3 1] payload))  (rsh [3 1] payload)
    $(lines t.lines, buffer [payload buffer])
  $(lines t.lines)
::
++  strip-cr
  |=  line=@t
  ^-  @t
  =/  len  (met 3 line)
  ?:  =(0 len)  line
  ?.  =('\0d' (rsh [3 (dec len)] line))  line
  (end [3 (dec len)] line)
::
++  flush-event
  |=  buffer=(list @t)
  ^-  (unit json)
  ?~  buffer  ~
  =/  text  (rap 3 (join '\0a' (flop buffer)))
  ?:  =('[DONE]' text)  ~
  (decode text)
::
::  +responses-result: openai responses api over sse. text is the
::  concatenation of completed message items; a completed response
::  event is required for success.
::
++  responses-result
  |=  events=(list json)
  ^-  provider-result
  =/  out=provider-result  [~ ~ %.n %.n %.n ~]
  =/  parts=(list @t)  ~
  |-
  ?~  events
    out(text ?~(parts ~ `(rap 3 (flop parts))))
  =/  event  i.events
  =/  kind  (string-or event 'type' '')
  ?:  =('response.output_item.done' kind)
    =/  item  (fall (get event 'item') ~)
    =/  item-kind  (string-or item 'type' '')
    ?:  =('message' item-kind)
      =/  content  (get-array item 'content')
      =/  texts
        %+  murn  content
        |=  part=json
        =/  part-kind  (string-or part 'type' '')
        ?:  =('output_text' part-kind)  (get-string part 'text')
        ~
      =/  refused
        (lien content |=(part=json =('refusal' (string-or part 'type' ''))))
      $(events t.events, parts (weld (flop texts) parts), out out(refusal |(refusal.out refused)))
    ?:  ?=(?(%'function_call' %'tool_call' %'custom_tool_call' %'local_shell_call' %'computer_call' %'apply_patch_call') item-kind)
      $(events t.events, out out(tool-call %.y))
    $(events t.events)
  ?:  =('response.completed' kind)
    =/  response  (fall (get event 'response') ~)
    =/  usage  (fall (get response 'usage') ~)
    =/  total=(unit @ud)
      =/  direct  (get-number usage 'total_tokens')
      ?^  direct  direct
      =/  input  (fall (get-number usage 'input_tokens') 0)
      =/  output  (fall (get-number usage 'output_tokens') 0)
      ?:(&(=(0 input) =(0 output)) ~ `(add input output))
    $(events t.events, out out(completed %.y, usage total))
  ?:  ?|(=('response.failed' kind) =('response.incomplete' kind) =('error' kind))
    =/  response  (fall (get event 'response') ~)
    =/  err  (fall (get response 'error') (fall (get event 'error') ~))
    =/  message  (string-or err 'message' (string-or event 'message' kind))
    $(events t.events, out out(error `message))
  $(events t.events)
::
::  +messages-result: anthropic messages api, one json body.
::
++  messages-result
  |=  body=@t
  ^-  provider-result
  =/  out=provider-result  [~ ~ %.n %.n %.n ~]
  =/  jon  (decode body)
  ?~  jon  out(error `'invalid-json')
  =/  kind  (string-or u.jon 'type' '')
  ?:  =('error' kind)
    =/  err  (fall (get u.jon 'error') ~)
    out(error `(string-or err 'message' (string-or err 'type' 'error')))
  =/  content  (get-array u.jon 'content')
  =/  texts
    %+  murn  content
    |=  part=json
    ?:  =('text' (string-or part 'type' ''))  (get-string part 'text')
    ~
  =/  tool  (lien content |=(part=json =('tool_use' (string-or part 'type' ''))))
  =/  usage  (fall (get u.jon 'usage') ~)
  =/  input  (fall (get-number usage 'input_tokens') 0)
  =/  output  (fall (get-number usage 'output_tokens') 0)
  =/  stop  (string-or u.jon 'stop_reason' '')
  %=  out
    text       ?~(texts ~ `(rap 3 texts))
    usage      ?:(&(=(0 input) =(0 output)) ~ `(add input output))
    completed  =('message' kind)
    tool-call  tool
    refusal    =('refusal' stop)
  ==
::
::  provider request bodies. no tools field is ever present.
::
++  responses-body
  |=  [model=@t instructions=@t input=@t]
  ^-  @t
  %-  en:json:html
  %-  pairs:enjs:format
  :~  ['model' s+model]
      ['instructions' s+instructions]
      :-  'input'
      :-  %a
      :_  ~
      %-  pairs:enjs:format
      :~  ['role' s+'user']
          ['content' [%a ~[(pairs:enjs:format ~[['type' s+'input_text'] ['text' s+input]])]]]
      ==
      ['store' b+%.n]
      ['stream' b+%.y]
  ==
::
++  messages-body
  |=  [model=@t system=@t input=@t max-tokens=@ud]
  ^-  @t
  %-  en:json:html
  %-  pairs:enjs:format
  :~  ['model' s+model]
      ['max_tokens' (numb:enjs:format max-tokens)]
      ['system' s+system]
      :-  'messages'
      :-  %a
      :_  ~
      %-  pairs:enjs:format
      :~  ['role' s+'user']
          ['content' [%a ~[(pairs:enjs:format ~[['type' s+'text'] ['text' s+input]])]]]
      ==
  ==
::
::  catalogs. only listed, api-usable models become profiles.
::
++  codex-catalog
  |=  body=@t
  ^-  (list [slug=@t label=@t])
  =/  jon  (decode body)
  ?~  jon  ~
  =/  rows  ?:(?=([%a *] u.jon) p.u.jon (get-array u.jon 'models'))
  =.  rows  ?~(rows (get-array u.jon 'data') rows)
  %+  murn  rows
  |=  row=json
  =/  slug  (fall (get-string row 'slug') (string-or row 'id' ''))
  ?:  =('' slug)  ~
  =/  visible  (string-or row 'visibility' 'list')
  ?.  =('list' visible)  ~
  =/  supported  (fall (get-bool row 'supported_in_api') %.y)
  ?.  supported  ~
  `[slug (string-or row 'display_name' slug)]
::
++  claude-catalog
  |=  body=@t
  ^-  (list [slug=@t label=@t])
  =/  jon  (decode body)
  ?~  jon  ~
  %+  murn  (get-array u.jon 'data')
  |=  row=json
  =/  id  (string-or row 'id' '')
  ?:  =('' id)  ~
  `[id (string-or row 'display_name' id)]
::
::  +html-text: deterministic extraction. scripts, styles, and comments
::  are dropped; tags become whitespace or line breaks; entities decode;
::  runs of whitespace collapse.
::
++  html-text
  |=  raw=@t
  ^-  @t
  =/  tap  (trip raw)
  =/  out=tape  ~
  |-
  ?~  tap  (crip (tidy (flop out)))
  =/  more=tape  tap
  ?.  =('<' i.tap)
    ?:  =('&' i.tap)
      =/  decoded  (entity more)
      $(tap tail.decoded, out (weld (flop text.decoded) out))
    $(tap t.tap, out [i.tap out])
  ?:  =("<!--" (scag 4 more))
    =/  close  (find "-->" more)
    $(tap ?~(close ~ (slag (add u.close 3) more)))
  =/  name  (tag-name t.tap)
  ?:  ?|(=("script" name) =("style" name) =("noscript" name) =("template" name) =("svg" name))
    =/  close  (find-close t.tap name)
    $(tap close, out [' ' out])
  =/  close  (find ">" more)
  =/  next  ?~(close ~ (slag +(u.close) more))
  ?:  (~(has in block-tags) (crip name))
    $(tap next, out ['\0a' out])
  $(tap next, out [' ' out])
::
++  block-tags
  ^-  (set @t)
  %-  silt
  ^-  (list @t)
  :~  'p'  'div'  'br'  'li'  'ul'  'ol'  'h1'  'h2'  'h3'  'h4'  'h5'  'h6'
      'tr'  'table'  'section'  'article'  'header'  'footer'  'pre'
      'blockquote'  'hr'  'dt'  'dd'  'title'  'nav'  'aside'  'main'
      'figure'  'figcaption'  'td'  'th'  'form'  'body'
  ==
::
++  tag-name
  |=  tap=tape
  ^-  tape
  =/  rest  ?:(?&(?=(^ tap) =('/' i.tap)) t.tap tap)
  %-  cass
  |-
  ?~  rest  ~
  ?.  ?|  &((gte i.rest 'a') (lte i.rest 'z'))
          &((gte i.rest 'A') (lte i.rest 'Z'))
          &((gte i.rest '0') (lte i.rest '9'))
      ==
    ~
  [i.rest $(rest t.rest)]
::
++  find-close
  |=  [tap=tape name=tape]
  ^-  tape
  =/  needle  (weld "</" name)
  =/  lowered  (cass tap)
  =/  at  (find needle lowered)
  ?~  at  ~
  =/  rest  (slag u.at tap)
  =/  close  (find ">" rest)
  ?~  close  ~
  (slag +(u.close) rest)
::
++  entity
  |=  tap=tape
  ^-  [text=tape tail=tape]
  ?~  tap  [~ ~]
  =/  more=tape  tap
  =/  after=tape  t.tap
  =/  semi  (find ";" (scag 12 more))
  ?~  semi  ["&" after]
  =/  name  (scag (dec u.semi) after)
  =/  rest  (slag +(u.semi) more)
  ?:  =("amp" name)  ["&" rest]
  ?:  =("lt" name)  ["<" rest]
  ?:  =("gt" name)  [">" rest]
  ?:  =("quot" name)  ["\"" rest]
  ?:  |(=("apos" name) =("#39" name))  ["'" rest]
  ?:  =("nbsp" name)  [" " rest]
  ?:  ?&(?=(^ name) =('#' i.name))
    =/  code=(unit @)
      ?:  ?&(?=(^ t.name) |(=('x' i.t.name) =('X' i.t.name)))
        (rush (crip t.t.name) hex)
      (rush (crip t.name) dem)
    ?~  code  [(weld "&" (weld name ";")) rest]
    ?:  |(=(0 u.code) (gth u.code 0x10.ffff))  [" " rest]
    [(trip (tuft u.code)) rest]
  [(weld "&" (weld name ";")) rest]
::
++  tidy
  |=  tap=tape
  ^-  tape
  =/  out=tape  ~
  =/  space=?  %.y
  =/  breaks=@ud  0
  |-
  ?~  tap  (flop out)
  =/  ch  i.tap
  ?:  =('\0a' ch)
    ?:  (gte breaks 2)  $(tap t.tap)
    $(tap t.tap, out ['\0a' out], space %.y, breaks +(breaks))
  ?:  ?|(=(' ' ch) =('\09' ch) =('\0d' ch))
    ?:  space  $(tap t.tap)
    $(tap t.tap, out [' ' out], space %.y)
  $(tap t.tap, out [ch out], space %.n, breaks 0)
--
