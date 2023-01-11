:: import the hut type defs from /sur/hut.hoon
::
/-  *hut
:: the mark door takes a $hut-act as its sample
::
|_  a=hut-act
:: grow defines methods for converting from this mark
:: to other marks
::
++  grow
  |%
  :: this mark is primarily used inbound from the 
  :: front-end, so we only need a simple %noun
  :: conversion method here
  ::
  ++  noun  a
  --
:: grab defines methods for converting to this mark
:: from other marks
::
++  grab
  |%
  :: for a plain noun we'll just mold it with the
  :: $hut-act mold
  ::
  ++  noun  hut-act
  :: we'll receive JSON data from the front-end,
  :: so we need methods to convert the json to
  :: a $hut-act
  ::
  ++  json
    :: we expose the contents of the dejs:format
    :: library so we don't have to type dejs:format
    :: every time we use its functions
    ::
    =,  dejs:format
    :: we create a gate that takes some $json
    ::
    |=  jon=json
    :: the return type is a $hut-act
    ::
    |^  ^-  hut-act
    :: we call our decoding function with the
    :: incoming JSON as its argument
    ::
    %.  jon
    :: ++of:dejs:format decodes objects into
    :: head-tagged structures. We define a method
    :: for each type of JSON-encoded $hut-action
    ::
    %-  of
    :~  new+(ot ~[hut+de-hut msgs+(ar de-msg)])
        post+(ot ~[hut+de-hut msg+de-msg])
        join+(ot ~[gid+de-gid who+(se %p)])
        quit+(ot ~[gid+de-gid who+(se %p)])
        del+(ot ~[hut+de-hut])
    ==
    :: this decodes a $msg from JSON
    ::
    ++  de-msg  (ot ~[who+(se %p) what+so])
    :: decode a $hut from JSON
    ::
    ++  de-hut  (ot ~[gid+de-gid name+(se %tas)])
    :: decode a squad $gid from JSON
    ::
    ++  de-gid  (ot ~[host+(se %p) name+(se %tas)])
    --
  --
:: grab handles revision control functions. We don't
:: need to use these, so we just delegate it to the
:: %noun mark
::
++  grad  %noun
--
