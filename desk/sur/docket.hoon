|%
::
+$  version
  [major=@ud minor=@ud patch=@ud]
::
+$  glob  (map path mime)
::
+$  url   cord
::  $glob-location: how to retrieve a glob
::
+$  glob-reference
  [hash=@uvH location=glob-location]
::
+$  glob-location
  $%  [%http =url]
      [%ames =ship]
  ==
::  $href: where a tile links to
::
+$  href
  $%  [%glob base=term =glob-reference]
      [%site =path]
  ==
::  $chad: state of a docket
::
+$  chad
  $~  [%install ~]
  $%  :: done
      [%glob =glob]
      [%site ~]
      :: waiting
      [%install ~]
      [%suspend glob=(unit glob)]
      :: error
      [%hung err=cord]
  ==
::
::  $charge: a realized $docket
::
+$  charge
  $:  =docket
      =chad
  ==
::
::  $clause: a key and value, as part of a docket
::
::    only used to parse $docket
::
+$  clause
  $%  [%title title=@t]
      [%info info=@t]
      [%color color=@ux]
      [%glob-http url=cord hash=@uvH]
      [%glob-ames =ship hash=@uvH]
      [%image =url]
      [%site =path]
      [%base base=term]
      [%version =version]
      [%website website=url]
      [%license license=cord]
  ==
::
::  $docket: a description of js bundles for a desk
::
+$  docket
  $:  %1
      title=@t
      info=@t
      color=@ux
      =href
      image=(unit url)
      =version
      website=url
      license=cord
  ==
::
+$  charge-update
  $%  [%initial initial=(map desk charge)]
      [%add-charge =desk =charge]
      [%del-charge =desk]
  ==
--
