:: first we import the type definitions of
:: the squad app and expose them
::
/-  *squad
|%
:: an individual chat message will be a pair
:: of the author and the message itself as
:: a string
::
+$  msg      [who=@p what=@t]
:: an individual hut will contain an ordered
:: list of such messages
::
+$  msgs     (list msg)
:: the name of a hut
::
+$  name     @tas
:: the full identifier of a hut - a pair of
:: a gid (squad id) and the name
::
+$  hut      [=gid =name]
:: huts will be how we store all the names
:: of huts in our state. It will be a map
:: from gid (squad id) to a set of hut names
::
+$  huts     (jug gid name)
:: this will contain the messages for all huts.
:: it's a map from hut to msgs
::
+$  msg-jar  (jar hut msg)
:: this tracks who has actually joined the huts
:: for a particular squad
::
+$  joined   (jug gid @p)
:: this is all the actions/requests that can
:: be initiated. It's one half of our app's
:: API. Things like creating a new hut,
:: posting a new message, etc.
::
+$  hut-act
  $%  [%new =hut =msgs]
      [%post =hut =msg]
      [%join =gid who=@p]
      [%quit =gid who=@p]
      [%del =hut]
  ==
:: this is the other half of our app's API:
:: the kinds of updates/events that can be
:: sent out to subscribers or our front-end.
:: It's the $hut-act items plus a couple of
:: additional structure to initialize the
:: state for new subscribers or front-ends.
::
+$  hut-upd
  $%  [%init =huts =msg-jar =joined]
      [%init-all =huts =msg-jar =joined]
      hut-act
  ==
--
