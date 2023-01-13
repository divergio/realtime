# Realtime Text Chat on Urbit

## Overview

Realtime is a top-and-bottom realtime text chat app built on Urbit. It lets you have a chat session with another user on urbit wherein you can see what the person is typing as they type, resulting in a more intimate, dynamic, and conversation feel. 

This is v0.2.0 of Realtime, which is based on a fork of the Urbit encrypted chat tutorial app [Hut](https://github.com/urbit/docs-examples/tree/main/chat-app) from `~tinnus-napbus`. 

https://user-images.githubusercontent.com/359631/212360920-0ef97803-4c7b-4be7-b092-8b49d26424b3.mov

## Context

Most of what people think of as chat is in the SMS style: one-by-one messages from each user in the chat. Some chat software adds things like "read indicators," user status bubbles, and *typing* indicators, but for the most part the experience is asynchronous. 

Real time chat (or realtime text, RTT), in contrast, lets you watch as someone composes a message. The result is an experience more like a conversation, with a more dynamic feel where the other person can interject or respond as the first person is composing their message. It's a fast and interactive way of conversing. 

## History
In the early internet, real time chat was more common. It was the main chat type in the popular chat app [ICQ](https://en.wikipedia.org/wiki/ICQ), and its lineage even traces back to early [Unix utilities](https://en.wikipedia.org/wiki/Talk_(software).

I've long had an affinity and nostalgia for this older form of chat, but it has fallen by the wayside as the SMS-style apps gained dominance. The form struggles on mobile, where slow typing speed frustrates communication. It's more suitable for desktop use, where typing speed and screen space are not limited. 

There have been attempts to make RTT-style apps for mobile devices: [Honk](https://honk.me) is one of the best recent implementations. However, like many traditional web2 apps, it [struggled](https://honk.me/sunset) to find a sustainable business model to support server costs and ongoing development. 

## Why Urbit? 
Which brings me to Urbit: Urbit is an ideal place to create a best-in-class RTT chat app. Current urbit chat lacks a sense of immediacy and closeness, RTT fixes this. Urbit is currently mostly used on desktop machines instead of mobile, so typing speed and screen space aren't a problem. Urbit aesthetics are more web1, so an old ICQ-like interface would feel right at home on your ship. Finally, the peer-to-peer nature resolves some of the concerns about business models and server costs.

## Installation (users)

The latest version of Realtime is served from the `~novrul-falfen` ship.

Realtime is dependent on the Squad app from `~pocwet`, so it must be installed first.

To install from the dojo: 
```
|install ~pocwet %squad
|install ~novrul-falfen %realtime
```

To install using the UI, see the latest instructions at [urbit.org](https://urbit.org/getting-started/installing-applications).

## Installation (developers)

For developers, follow the instructions in the [Build a Chat App](https://developers.urbit.org/guides/quickstart/chat-guide#put-it-together) Lightning tutorial in the Urbit Developers documentations. 

Realtime is a fork of `%hut`, simply perform the steps in the "Put it together" section, but substitute `%realtime` for `%hut`.

For the front-end resources, follow the instructions in realtime-ui/README.md and then glob the `realtime-ui/dist` folder. 

## Usage

To chat with your friend, both users must first install Squad and Realtime, then follow these instructions:

1. Use the Squad interface to create a squad. Be sure to give the squad a name, as it seems to cause problems in the interface if it doesn't have one. 
2. The second person should join the Squad. 
3. Launch Realtime, and select the created Squad from the left drop down (you might need to join from the right drop down first). 
4. Create a new chat by typing a name for the chat on the left "Chats" section.
5. Click into the chat.
6. The second user should launch realtime, select the Squad, and click into the chat as well.
7. Start typing, the other person can see everything as you type! 

## Limitations

**NOTE**: This version is using Squads to coordinate chat room creation. Ideally it should would work more like the existing chat app, letting you communicate with any urbit ship without first going through the Squad configuration. This is an artifact of my urbit app inexperience, the Squad codebase was smaller and more approachable than Chat for hacking. 

Realtime only supports chat between two users. It's pretty straightforward to increase this number, but the more users the more crowded the screen becomes.

Realtime doesn't work on mobile. The input box behavior seems to be the cause.

## App Structure and Explanation

Realtime consists first of the gall agent defined in `realtime.hoon`. This is basically the same as the `%hut` gall agent, with an additional tag on each message: `ephemeral`. Messages marked `ephemeral` are used for the text that is currently being typed, before it is "committed" by pressing enter. 

The second component is the React front-end defined in the `realtime-ui` directory. It lets you choose your squad, choose a chat room, and then send messages. The chat page polls your current input at a set interval (300-800ms), and sends updates with the `ephemeral` tag set to `"true"`. The chat display filters the messages to only display all the committed (non-ephemeral messages) with the most recent ephemeral message appended at the bottom. As new ephemeral messages come in, they replace the existing text. The result is real-time chat, where you can watch as the person types (albeit jerkily). 

## Future Work: Fluid Real Time Text

The most critical problem with the current solution is that text updates still happen in chunks: a new piece of text arrives with each message, resulting in a "jerky" appearance to the chat. 

When you heard about the polling interval, you might think that it's better to use a shorter interval or even get rid of the interval and send messages in response to keypresses. Unfortunately, not only could this result in spamming the network, neither solution actually resolves the jerkiness problem. 

Ultimately, jitter and latency in the network (which I suspect may be even worse on the urbit network, which sometimes has delayed messages) will result in some jerkiness or difference between how the person typed and how the text appears on the other persons screen. 

So how would we achieve fluid real time text that preserves the emotions of the original typer over an unstable network? Fortunately, someone has already solved it with a brilliant but elegant solution: Mark Rejhon's (XEP-0301: In-Band Real Time Text)[https://xmpp.org/extensions/xep-0301.html].

Briefly, what that specification describes is a technique for encoding the original time between key presses, transmitting them, and then reproducing them at the destination. It treats the text more like a video, using time stamps for each insertion and deletion, and sends a record of those key presses at regular intervals. The result is text appearing on screen that reproduces the look-and-feel of the typing of the sender, no matter the condition of the network separating the users. 

I believe it is relatively straightforward to adapt the techniques in XEP-0301 for use in a Urbit chat app. 

## Feature Wishlist 
- [X] "naive" RTT chat on Urbit 
- [ ] "fluid" RTT using XEP-0301
- [ ] Re-architect to not require Squads (maybe fork Talk?)
- [ ] Visual design revamp 
- [ ] Status indicators next to users name to show if they're present
- [ ] Clear button to clear all messages for one user
- [ ] Customizable backgrounds and fonts for each user (more personality)

## Links

[Project Slides Deck](https://docs.google.com/presentation/d/16Mh02aKftdPXX2NiXAo7vylEhDClc-crZQfWsdDGt7Y/edit?usp=sharing)
