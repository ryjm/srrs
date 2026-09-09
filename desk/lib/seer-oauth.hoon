::  provider sign-in and renewal codecs for %seer. the codex device flow
::  and the claude paste-back pkce flow run from the ship; tokens land in
::  the account slots of agent state. everything here is pure.
::
/-  *seer
/+  net=seer-net
|%
++  codex-client-id   'app_EMoamEEZ73f0CkXaXp7hrann'
++  claude-client-id  '9d1c250a-e61b-44d9-88ed-5944d1962f5e'
++  codex-usercode-url  'https://auth.openai.com/api/accounts/deviceauth/usercode'
++  codex-poll-url      'https://auth.openai.com/api/accounts/deviceauth/token'
++  codex-token-url     'https://auth.openai.com/oauth/token'
++  codex-device-page   'https://auth.openai.com/codex/device'
++  codex-redirect      'https://auth.openai.com/deviceauth/callback'
++  claude-authorize-url  'https://platform.claude.com/oauth/authorize'
++  claude-token-url      'https://platform.claude.com/v1/oauth/token'
++  claude-redirect       'https://platform.claude.com/oauth/code/callback'
++  claude-scopes         'org:create_api_key user:profile user:inference'
++  login-window  ~m15
++  renewal-margin  ~m5
++  renewal-window  ~s30
++  renewal-cooldown  ~m1
::
++  user-agent
  |=  provider=ai-provider
  ^-  @t
  ?-  provider
    %codex   codex-user-agent:net
    %claude  claude-user-agent:net
  ==
::
++  json-headers
  |=  provider=ai-provider
  ^-  header-list:http
  :~  ['content-type' 'application/json']
      ['accept' 'application/json']
      ['user-agent' (user-agent provider)]
  ==
::
++  form-headers
  |=  provider=ai-provider
  ^-  header-list:http
  :~  ['content-type' 'application/x-www-form-urlencoded']
      ['accept' 'application/json']
      ['user-agent' (user-agent provider)]
  ==
::
::  base64url without padding over the bytes of an atom, first byte first.
::
++  base64url
  |=  [len=@ud data=@]
  ^-  @t
  (~(en base64:mimes:html | &) [len data])
::
++  base64url-decode
  |=  text=@t
  ^-  (unit @t)
  =/  octs  (~(de base64:mimes:html | &) text)
  ?~  octs  ~
  `q.u.octs
::
::  +sha256-bytes: the digest as an octs whose first byte is the first
::  digest byte, so that base64 and hex renderings match other systems.
::
++  sha256-bytes
  |=  text=@t
  ^-  octs
  ::  +shax already yields the first digest byte in the low byte, which is
  ::  the octs order (RFC 7636 vector verified).
  [32 (shax text)]
::
++  random-token
  |=  [eny=@uvJ salt=@]
  ^-  @t
  =/  digest  (shax (jam [eny salt]))
  (base64url 32 digest)
::
::  +pkce: verifier, s256 challenge, and state from ship entropy.
::
++  pkce
  |=  eny=@uvJ
  ^-  [verifier=@t challenge=@t state=@t]
  =/  verifier  (random-token eny %verifier)
  =/  digest  (sha256-bytes verifier)
  :*  verifier
      (base64url p.digest q.digest)
      (random-token eny %state)
  ==
::
::  +jwt-claims: the decoded payload of a jws compact token, if any.
::
++  jwt-claims
  |=  token=@t
  ^-  (unit json)
  =/  parts  (rush token (more dot (cook crip (star ;~(less dot next)))))
  ?~  parts  ~
  ?.  =(3 (lent u.parts))  ~
  =/  payload  (base64url-decode (snag 1 u.parts))
  ?~  payload  ~
  =/  jon  (decode:net u.payload)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  jon
::
::  +jwt-expiry: an untrusted hint only; it never grants anything.
::
++  jwt-expiry
  |=  token=@t
  ^-  (unit @da)
  =/  claims  (jwt-claims token)
  ?~  claims  ~
  =/  exp  (get-number:net u.claims 'exp')
  ?~  exp  ~
  ?:  (gth u.exp 253.402.300.799)  ~
  `(add ~1970.1.1 (mul u.exp ~s1))
::
++  jwt-account
  |=  token=@t
  ^-  [account=@t label=@t]
  =/  claims  (jwt-claims token)
  ?~  claims  ['' '']
  =/  auth  (fall (get:net u.claims 'https://api.openai.com/auth') ~)
  =/  account
    =/  nested  (get-string:net auth 'chatgpt_account_id')
    ?^  nested  u.nested
    (string-or:net u.claims 'chatgpt_account_id' '')
  [account (string-or:net u.claims 'email' '')]
::
++  form-encode
  |=  fields=(list [@t @t])
  ^-  @t
  %+  rap  3
  %+  join  '&'
  %+  turn  fields
  |=  [key=@t value=@t]
  (rap 3 key '=' (crip (en-urlt:html (trip value))) ~)
::
::  codex device flow
::
++  usercode-request
  ^-  request:http
  %:  request:net  %'POST'  codex-usercode-url  (json-headers %codex)
    `(en:json:html (pairs:enjs:format ~[['client_id' s+codex-client-id]]))
  ==
::
++  parse-usercode
  |=  body=@t
  ^-  (unit [device-id=@t user-code=@t interval=@ud])
  =/  jon  (decode:net body)
  ?~  jon  ~
  =/  device  (get-string:net u.jon 'device_auth_id')
  =/  code  (get-string:net u.jon 'user_code')
  ?:  |(?=(~ device) ?=(~ code))  ~
  =/  interval  (fall (get-number:net u.jon 'interval') 5)
  `[u.device u.code (max 2 (min 60 interval))]
::
++  poll-request
  |=  [device-id=@t user-code=@t]
  ^-  request:http
  %:  request:net  %'POST'  codex-poll-url  (json-headers %codex)
    `(en:json:html (pairs:enjs:format ~[['device_auth_id' s+device-id] ['user_code' s+user-code]]))
  ==
::
+$  poll-outcome
  $%  [%pending ~]
      [%code code=@t verifier=@t]
      [%failed reason=@tas]
  ==
::
++  parse-poll
  |=  [status=@ud body=@t]
  ^-  poll-outcome
  =/  jon  (decode:net body)
  =/  code  ?~(jon ~ (get-string:net u.jon 'authorization_code'))
  ?:  ?&(=(200 status) ?=(^ code))
    [%code u.code ?~(jon '' (string-or:net u.jon 'code_verifier' ''))]
  ?:  ?|(=(202 status) =(403 status) =(404 status) =(400 status) =(428 status))
    =/  text  (lower:net body)
    ?:  !=(~ (find "device" (trip text)))
      ?:  ?|(!=(~ (find "disabled" (trip text))) !=(~ (find "not enabled" (trip text))))
        [%failed %device-auth-disabled]
      ?:  !=(~ (find "expired" (trip text)))  [%failed %expired]
      ?:  !=(~ (find "denied" (trip text)))  [%failed %denied]
      [%pending ~]
    ?:  !=(~ (find "expired" (trip text)))  [%failed %expired]
    ?:  !=(~ (find "denied" (trip text)))  [%failed %denied]
    [%pending ~]
  ?:  =(200 status)  [%pending ~]
  ?:  (gte status 500)  [%failed %unreachable]
  [%failed %denied]
::
++  codex-exchange-request
  |=  [code=@t verifier=@t]
  ^-  request:http
  %:  request:net  %'POST'  codex-token-url  (form-headers %codex)
    :-  ~
    %-  form-encode
    :~  ['grant_type' 'authorization_code']
        ['code' code]
        ['redirect_uri' codex-redirect]
        ['client_id' codex-client-id]
        ['code_verifier' verifier]
    ==
  ==
::
++  codex-refresh-request
  |=  refresh=@t
  ^-  request:http
  %:  request:net  %'POST'  codex-token-url  (form-headers %codex)
    :-  ~
    %-  form-encode
    :~  ['grant_type' 'refresh_token']
        ['client_id' codex-client-id]
        ['refresh_token' refresh]
    ==
  ==
::
::  claude paste-back flow
::
++  claude-authorize-link
  |=  [challenge=@t state=@t]
  ^-  @t
  %+  rap  3
  :~  claude-authorize-url
      '?code=true&client_id='  claude-client-id
      '&response_type=code&redirect_uri='  (crip (en-urlt:html (trip claude-redirect)))
      '&scope='  (crip (en-urlt:html (trip claude-scopes)))
      '&code_challenge='  challenge
      '&code_challenge_method=S256&state='  state
  ==
::
::  +split-pasted-code: the callback page shows code#state.
::
++  split-pasted-code
  |=  pasted=@t
  ^-  [code=@t state=@t]
  =/  tap  (trip pasted)
  =/  hash  (find "#" tap)
  ?~  hash  [pasted '']
  [(crip (scag u.hash tap)) (crip (slag +(u.hash) tap))]
::
++  claude-exchange-request
  |=  [code=@t state=@t verifier=@t]
  ^-  request:http
  %:  request:net  %'POST'  claude-token-url  (json-headers %claude)
    :-  ~
    %-  en:json:html
    %-  pairs:enjs:format
    :~  ['grant_type' s+'authorization_code']
        ['code' s+code]
        ['state' s+state]
        ['client_id' s+claude-client-id]
        ['redirect_uri' s+claude-redirect]
        ['code_verifier' s+verifier]
    ==
  ==
::
++  claude-refresh-request
  |=  refresh=@t
  ^-  request:http
  %:  request:net  %'POST'  claude-token-url  (json-headers %claude)
    :-  ~
    %-  en:json:html
    %-  pairs:enjs:format
    :~  ['grant_type' s+'refresh_token']
        ['refresh_token' s+refresh]
        ['client_id' s+claude-client-id]
    ==
  ==
::
++  refresh-request
  |=  [provider=ai-provider refresh=@t]
  ^-  request:http
  ?-  provider
    %codex   (codex-refresh-request refresh)
    %claude  (claude-refresh-request refresh)
  ==
::
::  +parse-token-response: a token grant from either provider.
::
+$  granted
  $:  access=@t
      refresh=@t
      expires=(unit @da)
      account=@t
      label=@t
      scopes=@t
  ==
::
++  parse-token-response
  |=  [provider=ai-provider now=@da body=@t]
  ^-  (unit granted)
  =/  jon  (decode:net body)
  ?~  jon  ~
  =/  access  (get-string:net u.jon 'access_token')
  ?~  access  ~
  ?:  =('' u.access)  ~
  =/  refresh  (fall (get-string:net u.jon 'refresh_token') '')
  =/  lifetime  (get-number:net u.jon 'expires_in')
  =/  hint  (jwt-expiry u.access)
  =/  expires=(unit @da)
    ?^  hint  hint
    ?~  lifetime  ~
    ?.  ?&((gth u.lifetime 60) (lte u.lifetime 31.536.000))  ~
    `(add now (mul u.lifetime ~s1))
  =/  id-token  (fall (get-string:net u.jon 'id_token') '')
  =/  [account=@t label=@t]
    ?-  provider
        %codex
      =/  from-id  (jwt-account id-token)
      ?:  !=('' account.from-id)  from-id
      (jwt-account u.access)
        %claude
      =/  acct  (fall (get:net u.jon 'account') ~)
      =/  org  (fall (get:net u.jon 'organization') ~)
      :-  (string-or:net acct 'uuid' (string-or:net org 'uuid' ''))
      (string-or:net acct 'email_address' (string-or:net org 'name' ''))
    ==
  `[u.access refresh expires account label (fall (get-string:net u.jon 'scope') '')]
::
::  +parse-pasted: credentials pasted by the operator. accepts the codex
::  auth.json shape, the claude credentials.json shape, a bare setup
::  token, an api key, or a generic token object.
::
+$  pasted
  $:  method=account-method
      access=@t
      refresh=@t
      expires=(unit @da)
      account=@t
      label=@t
      scopes=@t
  ==
::
++  parse-pasted
  |=  [provider=ai-provider now=@da text=@t]
  ^-  (unit pasted)
  =/  trimmed  (crip (trim-tape (trip text)))
  ?:  =('' trimmed)  ~
  =/  jon  (decode:net trimmed)
  ?~  jon  (parse-bare provider trimmed)
  ?.  ?=([%o *] u.jon)  (parse-bare provider trimmed)
  =/  tokens  (fall (get:net u.jon 'tokens') ~)
  =/  claude  (fall (get:net u.jon 'claudeAiOauth') ~)
  =/  access
    ;:  fall-string
      (get-string:net tokens 'access_token')
      (get-string:net claude 'accessToken')
      (get-string:net u.jon 'access_token')
      (get-string:net u.jon 'accessToken')
      (get-string:net u.jon 'auth-token')
      (get-string:net u.jon 'oauth_token')
      (get-string:net u.jon 'token')
      (get-string:net u.jon 'api_key')
      (get-string:net u.jon 'OPENAI_API_KEY')
      ~
    ==
  ?~  access  ~
  =/  refresh
    ;:  fall-string
      (get-string:net tokens 'refresh_token')
      (get-string:net claude 'refreshToken')
      (get-string:net u.jon 'refresh_token')
      (get-string:net u.jon 'refreshToken')
      ~
    ==
  =/  expires-ms  (get-number:net claude 'expiresAt')
  =/  expires=(unit @da)
    =/  hint  (jwt-expiry u.access)
    ?^  hint  hint
    ?~  expires-ms  ~
    `(add ~1970.1.1 (mul (div u.expires-ms 1.000) ~s1))
  =/  account
    ;:  fall-string
      (get-string:net tokens 'account_id')
      (get-string:net u.jon 'account_id')
      (get-string:net u.jon 'account')
      ~
    ==
  =/  id-token  (fall (get-string:net tokens 'id_token') '')
  =/  from-jwt  (jwt-account ?:(=('' id-token) u.access id-token))
  =/  scopes
    =/  arr  (get-array:net claude 'scopes')
    ?~  arr  (fall (get-string:net u.jon 'scope') '')
    (rap 3 (join ' ' (murn arr |=(j=json ?:(?=([%s *] j) `p.j ~)))))
  ::  an oauth access token shares the setup-token prefix; a refresh token
  ::  is what makes it renewable, so it decides the method.
  =/  method=account-method
    ?:  (is-api-key provider u.access)  %api-key
    ?:  ?&((is-setup-token u.access) ?|(?=(~ refresh) =('' u.refresh)))  %setup-token
    %oauth
  :-  ~
  :*  method
      u.access
      ?:(=(%api-key method) '' (fall refresh ''))
      ?:(=(%api-key method) ~ expires)
      (fall account account.from-jwt)
      label.from-jwt
      scopes
  ==
::
++  fall-string
  |=  [a=(unit @t) b=(unit @t)]
  ^-  (unit @t)
  ?^  a  ?:(=('' u.a) b a)
  b
::
++  parse-bare
  |=  [provider=ai-provider token=@t]
  ^-  (unit pasted)
  ?:  (lien (trip token) |=(ch=@ ?|(=(' ' ch) =('\0a' ch) =('\0d' ch) =('\09' ch))))
    ~
  ?:  (gth (met 3 token) 8.192)  ~
  =/  method=account-method
    ?:  (is-api-key provider token)  %api-key
    ?:  (is-setup-token token)  %setup-token
    %oauth
  =/  from-jwt  (jwt-account token)
  `[method token '' ?:(=(%oauth method) (jwt-expiry token) ~) account.from-jwt label.from-jwt '']
::
++  is-setup-token
  |=  token=@t
  ^-  ?
  =('sk-ant-oat' (end [3 10] token))
::
++  is-api-key
  |=  [provider=ai-provider token=@t]
  ^-  ?
  ?-  provider
    %claude  =('sk-ant-api' (end [3 10] token))
    %codex   ?&(=('sk-' (end [3 3] token)) !=('sk-ant' (end [3 6] token)))
  ==
::
++  trim-tape
  |=  tap=tape
  ^-  tape
  =/  space  |=(ch=@ ?|(=(' ' ch) =('\0a' ch) =('\0d' ch) =('\09' ch)))
  =/  front=tape
    |-  ^-  tape
    ?~  tap  ~
    ?.  (space i.tap)  tap
    $(tap t.tap)
  =/  back=tape  (flop front)
  %-  flop
  |-  ^-  tape
  ?~  back  ~
  ?.  (space i.back)  back
  $(back t.back)
::
::  +auth-headers: the credential and compatibility headers for a
::  provider api request under an account slot. never both kinds.
::
++  auth-headers
  |=  [provider=ai-provider account=provider-account]
  ^-  header-list:http
  ?-  provider
      %codex
    :*  ['authorization' (cat 3 'Bearer ' access.account)]
        ['user-agent' codex-user-agent:net]
        ['originator' 'codex_cli_rs']
        ?:  ?&(=(%oauth method.account) !=('' account.account))
          ~[['chatgpt-account-id' account.account]]
        ~
    ==
      %claude
    :*  ['anthropic-version' '2023-06-01']
        ['user-agent' claude-user-agent:net]
        ?:  =(%api-key method.account)
          ~[['x-api-key' access.account]]
        :~  ['authorization' (cat 3 'Bearer ' access.account)]
            ['anthropic-beta' 'oauth-2025-04-20']
        ==
    ==
  ==
::
++  generation-url
  |=  [provider=ai-provider account=provider-account]
  ^-  @t
  ?-  provider
    %codex   ?:(=(%api-key method.account) codex-api-url:net codex-oauth-url:net)
    %claude  claude-messages-url:net
  ==
::
++  catalog-url
  |=  [provider=ai-provider account=provider-account]
  ^-  @t
  ?-  provider
    %codex   ?:(=(%api-key method.account) codex-catalog-api:net codex-catalog-oauth:net)
    %claude  claude-catalog-url:net
  ==
::
::  +renewal-state: whether an account can be used now, needs renewal
::  first, or is blocked, given the ship time.
::
++  renewal-state
  |=  [account=provider-account now=@da]
  ^-  ?(%usable %renew %renewing %cooldown %terminal %expired)
  ?.  =(%oauth method.account)  %usable
  ?^  active.renewal.account  %renewing
  =/  expiring=?
    ?~  expires.account  %.n
    (gte (add now renewal-margin) u.expires.account)
  ?.  expiring  %usable
  ?:  =('' refresh.account)  %expired
  ?:  terminal.renewal.account  %terminal
  ?:  (lth now retry-at.renewal.account)  %cooldown
  %renew
::
++  view-of-account
  |=  account=provider-account
  ^-  account-view
  :*  method.account
      account.account
      expires.account
      scopes.account
      observed-at.account
      ?=(^ active.renewal.account)
      error.renewal.account
      terminal.renewal.account
  ==
--
