:: first we import the type defs for hut and also
:: for the squad app
::
/-  *hut, *squad
:: we also import some utility libraries to
:: reduce boilerplate
::
/+  default-agent, dbug, agentio
:: next, we define the type of our agent's state.
:: We create a versioned-state structure so it's
:: easy to upgrade down the line, then we define
:: state-0 as the type of our state
::
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 =huts =msg-jar =joined]
+$  card  card:agent:gall
--
:: we wrap our agent in the dbug library so we
:: can easily debug it from the dojo if needed
::
%-  agent:dbug
:: we pin the default value of our $state-0
:: structure and give it the alias of "state"
::
=|  state-0
=*  state  -
:: we cast our agent to an agent type
::
^-  agent:gall
:: we reverse-compose in a separate helper core
:: defined below the main agent. This contains a
:: few useful functions
::
=<
:: we then start the agent core proper. It takes
:: a bowl containing metadata like the current time,
:: some entropy, the source of the current request, etc.
:: Gall automatically populates this every time there's
:: an event
::
|_  bol=bowl:gall
:: we define a few aliases for convenience. "This" is
:: the entire agent core including its state. "Def" is
:: the default-agent library. "IO" is the agentio
:: library and "hc" is our helper core.
::
+*  this  .
    def   ~(. (default-agent this %.n) bol)
    io    ~(. agentio bol)
    hc    ~(. +> bol)
:: this is the first proper agent arm. On-init is called
:: exactly once, when an agent is first installed. We just
:: subscribe to the %squad app for squad updates.
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  (~(watch-our pass:io /squad) %squad /local/all)
  ==
:: on-save exports the state of the agent, and is called
:: either when an upgrade occurs or when the agent is suspended
::
++  on-save  !>(state)
:: on-load imports a previously exported agent state. It's called
:: after an upgrade has completed or when an agent has been
:: unsuspended. It just puts the state back in its proper location.
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  [~ this(state !<(state-0 old-vase))]
:: on-poke handles "pokes", one-off requests/actions intiated either
:: by our local ship, the front-end or other ships on the network.
::
++  on-poke
  |=  [=mark =vase]
  |^  ^-  (quip card _this)
  :: we assert it's a %hut-do mark containing the $action type we
  :: previously defined
  ::
  ?>  ?=(%hut-do mark)
  :: we check whether the request came from our ship (and its front-end),
  :: or another ship on the network. If it's from us we call ++local, if
  :: it's from someone else we call ++remote
  ::
  ?:  =(our.bol src.bol)
    (local !<(hut-act vase))
  (remote !<(hut-act vase))
  :: ++local handles requests from our local ship and its front-end
  ::
  ++  local
    :: it takes a $hut-action
    ::
    |=  act=hut-act
    ^-  (quip card _this)
    :: we switch on the type of request
    ::
    ?-    -.act
      :: posting a new message
      ::
        %post
      =/  =path
        /(scot %p host.gid.hut.act)/[name.gid.hut.act]
      :: if it's a remote hut, we pass the request to the host ship
      ::
      ?.  =(our.bol host.gid.hut.act)
        :_  this
        :~  (~(poke pass:io path) [host.gid.hut.act %hut] [mark vase])
        ==
      :: if it's our hut, we add the message to the hut
      ::
      =/  =msgs  (~(get ja msg-jar) hut.act)
      =.  msgs
        ?.  (lte 50 (lent msgs))
          [msg.act msgs]
        [msg.act (snip msgs)]
      :: we update the msgs in state and send an update to
      :: all subscribers
      ::
      :_  this(msg-jar (~(put by msg-jar) hut.act msgs))
      :~  (fact:io hut-did+vase path /all ~)
      ==
    ::
      :: a request to subscribe to a squad's huts
      ::
        %join
      :: make sure it's not our own
      ::
      ?<  =(our.bol host.gid.act)
      :: pass the request along to the host
      ::
      =/  =path
        /(scot %p host.gid.act)/[name.gid.act]
      :_  this
      :~  (~(watch pass:io path) [host.gid.act %hut] path)
      ==
    ::
      :: unsubscribe from huts for a squad
      ::
        %quit
      =/  =path
        /(scot %p host.gid.act)/[name.gid.act]
      :: get the squad's huts from state
      ::
      =/  to-rm=(list hut)
        %+  turn  ~(tap in (~(get ju huts) gid.act))
        |=(=name `hut`[gid.act name])
      :: delete all messages for those huts
      ::
      =.  msg-jar
        |-
        ?~  to-rm  msg-jar
        $(to-rm t.to-rm, msg-jar (~(del by msg-jar) i.to-rm))
      :: notify subscribers & unsubscribe from the host if it's
      :: not our. Also update state to delete all the huts,
      :: messages and members
      ::
      :-  :-  (fact:io hut-did+vase /all ~)
          ?:  =(our.bol host.gid.act)
            ~
          ~[(~(leave-path pass:io path) [host.gid.act %hut] path)]
      %=  this
        huts     (~(del by huts) gid.act)
        msg-jar  msg-jar
        joined   (~(del by joined) gid.act)
      ==
    ::
      :: create a new hut
      ::
        %new
      :: make sure we're creating a hut in our own squad
      ::
      ?>  =(our.bol host.gid.hut.act)
      :: make sure the specified squad exists
      ::
      ?>  (has-squad:hc gid.hut.act)
      :: make sure the new hut doesn't already exist
      ::
      ?<  (~(has ju huts) gid.hut.act name.hut.act)
      :: notify subscribers and initialize the new
      :: hut in state
      ::
      =/  =path
        /(scot %p host.gid.hut.act)/[name.gid.hut.act]
      :-  :~  (fact:io hut-did+vase path /all ~)
          ==
      %=  this
        huts     (~(put ju huts) gid.hut.act name.hut.act)
        msg-jar  (~(put by msg-jar) hut.act *msgs)
        joined   (~(put ju joined) gid.hut.act our.bol)
      ==
    ::
      :: delete a hut
      ::
        %del
      :: make sure we're the host
      ::
      ?>  =(our.bol host.gid.hut.act)
      :: notify subscribers and delete its messages and
      :: metadata in state
      ::
      =/  =path
        /(scot %p host.gid.hut.act)/[name.gid.hut.act]
      :-  :~  (fact:io hut-did+vase path /all ~)
          ==
      %=  this
        huts     (~(del ju huts) gid.hut.act name.hut.act)
        msg-jar  (~(del by msg-jar) hut.act)
      ==
    ==
  :: ++remote handles requests from remote ships
  ::
  ++  remote
    :: it takes a $hut-act
    ::
    |=  act=hut-act
    :: assert it can only be a %post message request
    ::
    ?>  ?=(%post -.act)
    ^-  (quip card _this)
    :: make sure we host the hut in question
    ::
    ?>  =(our.bol host.gid.hut.act)
    :: make sure it exists
    ::
    ?>  (~(has by huts) gid.hut.act)
    :: make sure the source of the request is the specified
    :: author
    ::
    ?>  =(src.bol who.msg.act)
    :: make sure the source of the request is a member
    ::
    ?>  (~(has ju joined) gid.hut.act src.bol)
    =/  =path  /(scot %p host.gid.hut.act)/[name.gid.hut.act]
    :: get that hut's messages from state
    ::
    =/  =msgs  (~(get ja msg-jar) hut.act)
    :: add the new message
    ::
    =.  msgs
      ?.  (lte 50 (lent msgs))
        [msg.act msgs]
      [msg.act (snip msgs)]
    :: notify subscribers of the new message and update state
    ::
    :_  this(msg-jar (~(put by msg-jar) hut.act msgs))
    :~  (fact:io hut-did+vase path /all ~)
    ==
  --
:: on-agent handles responses to requests we've initiated
:: and updates/events from those to whom we've subscribed
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  :: if it's from the Squad app
  ::
  ?:  ?=([%squad ~] wire)
    :: switch on the type of event
    ::
    ?+    -.sign  (on-agent:def wire sign)
      :: if we've been kicked from the subscription,
      :: automatically resubscribe
      ::
        %kick
      :_  this
      :~  (~(watch-our pass:io /squad) %squad /local/all)
      ==
    ::
      :: if it's a subscription acknowledgement, see if
      :: the subscribe succeeded or failed
      ::
        %watch-ack
      :: if there's no error message it succceeded,
      :: do nothing further
      ::
      ?~  p.sign  `this
      :: otherwise if there's an error message it failed,
      :: set a timer to retry subscribing in 1 minute
      ::
      :_  this
      :~  (~(wait pass:io /behn) (add now.bol ~m1))
      ==
    ::
      :: if it's an ordinary subscription update...
      ::
        %fact
      :: assert it's a %squad-did mark containing a Squad $upd
      ::
      ?>  ?=(%squad-did p.cage.sign)
      :: extract the squad $upd update
      ::
      =/  =upd  !<(upd q.cage.sign)
      :: switch on the kind of update
      ::
      ?+    -.upd  `this
        :: if it's a state initialization update...
        ::
          %init-all
        :: diff the squads we have with those in the update,
        :: making a list of the ones we have that aren't in the
        :: update and that we therefore need to remove
        ::
        =/  gid-to-rm=(list gid)
          ~(tap in (~(dif in ~(key by huts)) ~(key by squads.upd)))
        :: delete the $huts entries for those
        ::
        =.  huts
          |-
          ?~  gid-to-rm  huts
          $(gid-to-rm t.gid-to-rm, huts (~(del by huts) i.gid-to-rm))
        :: delete the member lists for those
        ::
        =.  joined
          |-
          ?~  gid-to-rm  joined
          $(gid-to-rm t.gid-to-rm, joined (~(del by joined) i.gid-to-rm))
        :: make a list of huts to remove based on the squads to remove
        ::
        =/  hut-to-rm=(list hut)
          %-  zing
          %+  turn  gid-to-rm
          |=  =gid
          (turn ~(tap in (~(get ju huts) gid)) |=(=name `hut`[gid name]))
        :: delete all message container entries for those huts
        ::
        =.  msg-jar
          |-
          ?~  hut-to-rm  msg-jar
          $(hut-to-rm t.hut-to-rm, msg-jar (~(del by msg-jar) i.hut-to-rm))
        :: kick all members of removed squads and create notifications
        :: of their kicks to send to subscribers
        ::
        =^  cards=(list card)  joined
          %+  roll  ~(tap by joined)
          |:  [[gid=*gid ppl=*ppl] cards=*(list card) n-joined=joined]
          =/  =path  /(scot %p host.gid)/[name.gid]
          =/  ppl-list=(list @p)  ~(tap in ppl)
          =;  [n-cards=(list card) n-n-joined=^joined]
            [(weld n-cards cards) n-n-joined]
          %+  roll  ppl-list
          |:  [ship=*@p n-cards=*(list card) n-n-joined=n-joined]
          ?.  ?&  ?|  ?&  pub:(~(got by squads.upd) gid)
                          (~(has ju acls.upd) gid ship)
                      ==
                      ?&  !pub:(~(got by squads.upd) gid)
                          !(~(has ju acls.upd) gid ship)
                      ==
                  ==
                  (~(has ju n-n-joined) gid ship)
              ==
            [n-cards n-n-joined]
          :-  :+  (kick-only:io ship path ~)
                (fact:io hut-did+!>(`hut-upd`[%quit gid ship]) path /all ~)
              n-cards
          (~(del ju n-n-joined) gid ship)
        =/  kick-paths=(list path)
          (turn gid-to-rm |=(=gid `path`/(scot %p host.gid)/[name.gid]))
        =.  cards  ?~(kick-paths cards [(kick:io kick-paths) cards])
        =.  cards
          %+  weld
            %+  turn  gid-to-rm
            |=  =gid
            ^-  card
            (fact:io hut-did+!>(`hut-upd`[%quit gid our.bol]) /all ~)
          cards
        :: update state and send off the notifications
        ::
        [cards this(huts huts, msg-jar msg-jar, joined joined)]
      ::
        :: a squad has been deleted
        ::
          %del
        =/  =path  /(scot %p host.gid.upd)/[name.gid.upd]
        :: get the huts of the deleted squad
        ::
        =/  to-rm=(list hut)
          %+  turn  ~(tap in (~(get ju huts) gid.upd))
          |=(=name `hut`[gid.upd name])
        :: delete messages for those huts
        ::
        =.  msg-jar
          |-
          ?~  to-rm  msg-jar
          $(to-rm t.to-rm, msg-jar (~(del by msg-jar) i.to-rm))
        :: update state
        ::
        :_  %=  this
              huts     (~(del by huts) gid.upd)
              msg-jar  msg-jar
              joined   (~(del by joined) gid.upd)
            ==
        :: kick all subscribers for that squad and unsubscribe if
        :: it's not ours
        ::
        :+  (kick:io path ~)
          (fact:io hut-did+!>(`hut-upd`[%quit gid.upd our.bol]) /all ~)
        ?:  =(our.bol host.gid.upd)
          ~
        ~[(~(leave-path pass:io path) [host.gid.upd %tally] path)]
      ::
        :: someone has been kicked from a squad
        ::
          %kick
        =/  =path  /(scot %p host.gid.upd)/[name.gid.upd]
        :: if it wasn't us: kick them, delete them from the member set
        :: and notify subscribers of the kick
        ::
        ?.  =(our.bol ship.upd)
          :_  this(joined (~(del ju joined) gid.upd ship.upd))
          :-  (kick-only:io ship.upd path ~)
          ?.  (~(has ju joined) gid.upd ship.upd)
            ~
          ~[(fact:io hut-did+!>(`hut-upd`[%quit gid.upd ship.upd]) path /all ~)]
        :: if we were kicked, get all huts for that squad
        ::
        =/  hut-to-rm=(list hut)
          (turn ~(tap in (~(get ju huts) gid.upd)) |=(=name `hut`[gid.upd name]))
        :: delete all messages for those huts
        ::
        =.  msg-jar
          |-
          ?~  hut-to-rm  msg-jar
          $(hut-to-rm t.hut-to-rm, msg-jar (~(del by msg-jar) i.hut-to-rm))
        :: update state and kick subscribers
        ::
        :_  %=  this
               huts     (~(del by huts) gid.upd)
               msg-jar  msg-jar
               joined   (~(del by joined) gid.upd)
            ==
        :+  (kick:io path ~)
          (fact:io hut-did+!>(`hut-upd`[%quit gid.upd ship.upd]) /all ~)
        ?:  =(our.bol host.gid.upd)
          ~
        ~[(~(leave-path pass:io path) [host.gid.upd %tally] path)]
      ::
        :: someone has left a squad
        ::
          %leave
        =/  =path  /(scot %p host.gid.upd)/[name.gid.upd]
        :: if it wasn't us, remove them from the members list
        :: and notify subscribers that they quit
        ::
        ?.  =(our.bol ship.upd)
          ?.  (~(has ju joined) gid.upd ship.upd)
            `this
          :_  this(joined (~(del ju joined) gid.upd ship.upd))
          :~  (kick-only:io ship.upd path ~)
              %+  fact:io
                hut-did+!>(`hut-upd`[%quit gid.upd ship.upd])
              ~[path /all]
          ==
        :: if it was us, get a list of that squad's huts
        ::
        =/  hut-to-rm=(list hut)
          (turn ~(tap in (~(get ju huts) gid.upd)) |=(=name `hut`[gid.upd name]))
        :: delete all messages for those huts
        ::
        =.  msg-jar
          |-
          ?~  hut-to-rm  msg-jar
          $(hut-to-rm t.hut-to-rm, msg-jar (~(del by msg-jar) i.hut-to-rm))
        :: update state and kick all subscribers to this squad
        ::
        :_  %=  this
              huts     (~(del by huts) gid.upd)
              msg-jar  msg-jar
              joined   (~(del by joined) gid.upd)
            ==
        :+  (kick:io path ~)
          (fact:io hut-did+!>(`hut-upd`[%quit gid.upd ship.upd]) /all ~)
        ?:  =(our.bol host.gid.upd)
          ~
        ~[(~(leave-path pass:io path) [host.gid.upd %tally] path)]
      ==
    ==
  :: otherwise the event is from another tally instance we've
  :: subscribed to
  ::
  ?>  ?=([@ @ ~] wire)
  :: decode the squad from the wire (event tag)
  ::
  =/  =gid  [(slav %p i.wire) i.t.wire]
  :: switch on the kind of event
  ::
  ?+    -.sign  (on-agent:def wire sign)
    :: if it was a response to a subscriiption request...
      %watch-ack
    :: if there's no error message the subscription succeeded,
    :: no nothing
    ?~  p.sign  `this
    :: otherwise it failed. Get a list of the huts for that squad
    ::
    =/  to-rm=(list hut)
      %+  turn  ~(tap in (~(get ju huts) gid))
      |=(=name `hut`[gid name])
    :: delete all its messages
    ::
    =.  msg-jar
      |-
      ?~  to-rm  msg-jar
      $(to-rm t.to-rm, msg-jar (~(del by msg-jar) i.to-rm))
    :: update state and send notification
    ::
    :-  :~  (fact:io hut-did+!>(`hut-upd`[%quit gid our.bol]) /all ~)
        ==
    %=  this
      huts     (~(del by huts) gid)
      msg-jar  msg-jar
      joined   (~(del by joined) gid)
    ==
  ::
    :: if we've been kicked from the subscription,
    :: automatically resubscribe
    ::
      %kick
    :_  this
    :~  (~(watch pass:io wire) [host.gid %hut] wire)
    ==
  ::
    :: if it's an ordinary subscription update...
    ::
      %fact
    :: assert the update has a %hut-did mark and
    :: contains a $hut-upd
    ::
    ?>  ?=(%hut-did p.cage.sign)
    :: extract the $hut-upd
    ::
    =/  upd  !<(hut-upd q.cage.sign)
    :: switch on what kind of update it is
    ::
    ?+    -.upd  (on-agent:def wire sign)
      :: a state initialization update
      ::
        %init
      :: if it's trying to initialize squads other
      :: than it should, do nothing
      ::
      ?.  =([gid ~] ~(tap in ~(key by huts.upd)))
        `this
      :: if it's trying to overwrite members for squads
      :: other than it should, do nothing
      ::
      ?.  =([gid ~] ~(tap in ~(key by joined.upd)))
        `this
      :: delete huts we have that no longer exist for this
      :: squad and update the messages for the rest
      ::
      =.  msg-jar.upd
        =/  to-rm=(list [=hut =msgs])
          %+  skip  ~(tap by msg-jar.upd)
          |=  [=hut =msgs]
          ?&  =(gid gid.hut)
              (~(has ju huts.upd) gid.hut name.hut)
          ==
        |-
        ?~  to-rm
          msg-jar.upd
        $(to-rm t.to-rm, msg-jar.upd (~(del by msg-jar.upd) hut.i.to-rm))
      :: pass on the %init event to the front-end and update state
      ::
      :-  :~  %+  fact:io
                hut-did+!>(`hut-upd`[%init huts.upd msg-jar.upd joined.upd])
              ~[/all]
          ==
      %=  this
        huts     (~(uni by huts) huts.upd)
        msg-jar  (~(uni by msg-jar) msg-jar.upd)
        joined   (~(uni by joined) joined.upd)
      ==
    ::
      :: a new message
      ::
        %post
      ?.  =(gid gid.hut.upd)
        `this
      :: update messages for the hut in question
      ::
      =/  msgs  (~(get ja msg-jar) hut.upd)
      =.  msgs
        ?.  (lte 50 (lent msgs))
          [msg.upd msgs]
        [msg.upd (snip msgs)]
      :: update state and notify the front-end
      ::
      :_  this(msg-jar (~(put by msg-jar) hut.upd msgs))
      :~  (fact:io cage.sign /all ~)
      ==
    ::
      :: someone has joined the huts for a squad
      ::
        %join
      ?.  =(gid gid.upd)
        `this
      :: update the member list and notify the front-end
      ::
      :_  this(joined (~(put ju joined) gid who.upd))
      :~  (fact:io cage.sign /all ~)
      ==
    ::
      :: someone has left the huts for a squad
      ::
        %quit
      ?.  =(gid gid.upd)
        `this
      :: update thje member list and notify the front-end
      ::
      :_  this(joined (~(del ju joined) gid who.upd))
      :~  (fact:io cage.sign /all ~)
      ==
    ::
      :: a hut has been deleted
      ::
        %del
      ?.  =(gid gid.hut.upd)
        `this
      :: notify the front-end and delete everything about
      :: it in state
      :-  :~  (fact:io cage.sign /all ~)
          ==
      %=  this
        huts     (~(del ju huts) hut.upd)
        msg-jar  (~(del by msg-jar) hut.upd)
      ==
    ==
  ==
:: on-watch handles subscription requests
::
++  on-watch
  :: it takes the requested subscription path as its argument
  ::
  |=  =path
  |^  ^-  (quip card _this)
  :: if it's /all...
  ?:  ?=([%all ~] path)
    :: assert it must be from the local ship (and front-end)
    ::
    ?>  =(our.bol src.bol)
    :: give the subscriber the current state of all huts
    ::
    :_  this
    :~  %-  fact-init:io
        hut-did+!>(`hut-upd`[%init-all huts msg-jar joined])
    ==
  :: otherwise it's a probably a remote ship subscribing
  :: to huts for a particular squad
  ::
  ?>  ?=([@ @ ~] path)
  :: decode the gid (squad id)
  ::
  =/  =gid  [(slav %p i.path) i.t.path]
  :: assert we're the host
  ::
  ?>  =(our.bol host.gid)
  :: assert the requester is a member of the squad in question
  ::
  ?>  (is-allowed:hc gid src.bol)
  :: update the member list, give them the initial state of huts
  :: for that squad and notify all other subscribers of the join
  ::
  :_  this(joined (~(put ju joined) gid src.bol))
  :-  (init gid)
  ?:  (~(has ju joined) gid src.bol)
    ~
  ~[(fact:io hut-did+!>(`hut-upd`[%join gid src.bol]) /all path ~)]
  :: this is just a convenience function to construct the
  :: initialization update for new subscribers
  ::
  ++  init
    |=  =gid
    ^-  card
    =/  hut-list=(list hut)
      %+  turn  ~(tap in (~(get ju huts) gid))
      |=(=name `hut`[gid name])
    %-  fact-init:io
    :-  %hut-did
    !>  ^-  hut-upd
    :^    %init
        (~(put by *^huts) gid (~(get ju huts) gid))
      %-  ~(gas by *^msg-jar)
      %+  turn  hut-list
      |=(=hut `[^hut msgs]`[hut (~(get ja msg-jar) hut)])
    (~(put by *^joined) gid (~(put in (~(get ju joined) gid)) src.bol))
  --
:: on-leave is called when someone unsubscribes
::
++  on-leave
  |=  =path
  ^-  (quip card _this)
  :: if it's /all (and therefore the front-end), do nothing
  ::
  ?:  ?=([%all ~] path)
    `this
  :: otherwise it's probably a remote ship leaving
  ::
  ?>  ?=([@ @ ~] path)
  :: decode the gid (squad id)
  ::
  =/  =gid  [(slav %p i.path) i.t.path]
  :: check if this is the only subscription the person leaving
  :: has with us
  ::
  =/  last=?
    %+  gte  1
    (lent (skim ~(val by sup.bol) |=([=@p *] =(src.bol p))))
  :: update state and alert other subscribers that they left
  :: if it's the only subscription they have
  ::
  :_  this(joined (~(del ju joined) gid src.bol))
  ?.  last
    ~
  :~  (fact:io hut-did+!>(`hut-upd`[%quit gid src.bol]) /all path ~)
  ==
:: on-peek handles local read-only requests. We don't use it so
:: we leave it to default-agent to handle
::
++  on-peek  on-peek:def
:: on-arvo handles responses from the kernel
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  :: if it's not from Behn (the timer vane), do nothing
  ::
  ?.  ?=([%behn ~] wire)
    (on-arvo:def [wire sign-arvo])
  ?>  ?=([%behn %wake *] sign-arvo)
  :: if the timer fired successfully, resubscribe to the squad app
  ::
  ?~  error.sign-arvo
    :_  this
    :~  (~(watch-our pass:io /squad) %squad /local/all)
    ==
  :: otherwise, if the timer failed for some reason, reset it
  ::
  :_  this
  :~  (~(wait pass:io /behn) (add now.bol ~m1))
  ==
:: on-fail handles crash notifications. We just leave it to
:: default-agent
::
++  on-fail  on-fail:def
--
:: that's the end of the agent core proper. Now we have the
:: "helper core" that we reverse-composed into the main
:: agent core's subject. It contains some useful functions
:: we use in our agent in various places.
::
:: it takes the same bowl as the main agent
::
|_  bol=bowl:gall
:: this function checks whether a squad exists in our local
:: squad agent
::
++  has-squad
  |=  =gid
  ^-  ?
  =-  ?=(^ .)
  .^  (unit)
    %gx
    (scot %p our.bol)
    %squad
    (scot %da now.bol)
    %squad
    (scot %p host.gid)
    /[name.gid]/noun
  ==
:: this function checks whether a ship should be allowed to subscribe,
:: based on the access control list for the squad in the squad app
::
++  is-allowed
  |=  [=gid =ship]
  ^-  ?
  =/  u-acl
    .^  (unit [pub=? acl=ppl])
      %gx
      (scot %p our.bol)
      %squad
      (scot %da now.bol)
      %acl
      (scot %p host.gid)
      /[name.gid]/noun
    ==
  ?~  u-acl  |
  ?:  pub.u.u-acl
    !(~(has in acl.u.u-acl) ship)
  (~(has in acl.u.u-acl) ship)
--
