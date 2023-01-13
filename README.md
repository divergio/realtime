# Realtime Text Chat on Urbit

## Overview

Realtime is a top-and-bottom realtime text chat app built on Urbit. It lets you have a chat session with another user on urbit wherein you can see what the person is typing as they type, resulting in a more intimate, dynamic, and conversation feel. 

This is v0.2.0 of Realtime, which is based on a fork of the Urbit encrypted tutorial app [Hut](https://github.com/urbit/docs-examples/tree/main/chat-app) from `~tinnus-napbus`. 

## Context

Most of what people think of as chat is in the SMS style: one-by-one messages from each user in the chat. Some chat software adds things like "read indicators," user status bubbles, and *typing* indicators, but for the most part the experience is asynchronous. 

Real time chat (or realtime text, RTT), in contrast, lets you watch as someone composes a message. The result is an experience more like a conversation, with a more dynamic feel where the other person can interject or respond as the first person is composing their message. 

In the early internet, real time chat was more common. It was the main chat type in [ICQ](https://en.wikipedia.org/wiki/ICQ), and its lineage even traces back to early [Unix utilities](https://en.wikipedia.org/wiki/Talk_(software).

I've long had an affinity and nostalgia for this older form of chat, but it has fallen by the wayside as the SMS-style apps gained dominance. The form is more suitable for desktop use, where typing speed and screen space are not limited. The form struggles on mobile, where slow typing speed frustrates communication and where screen space is much more limited. 

There have been attempts to make RTT-style apps for mobile devices, [Honk](https://honk.me) is one of the best recent implementations. However, like many traditional web2 apps, it [struggled](https://honk.me/sunset) to find a sustainable business model to support server costs and ongoing development. 

Which brings me to Urbit: Urbit is an ideal place to create a best-in-class RTT chat app. Current urbit chat lacks a sense of immediacy and closeness, RTT fixes this. Urbit is currently mostly used on desktop machines instead of mobile, so typing speed and screen space aren't a problem. Urbit aesthetics are more web1, so an old ICQ-like interface would feel right at home on your ship. Finally, the peer-to-peer nature also assuages some of the concerns about business models and server costs.

TODO: some screenshots and links here

![Dashboard](https://imgur.com/HILKB03.png)

[![Algo AMM](https://yt-embed.herokuapp.com/embed?v=uePtNvBP3oQ)](https://youtu.be/uePtNvBP3oQ "Algo AMM")

[Project Slides Deck](https://docs.google.com/presentation/d/1FBchISurC6Fsy-iEkmQ4gggEs7i6D4pRHab8gwOEyqk/edit?usp=sharing)

We wrote contract for Prediction Market Constant Function Automated Market Maker with the help of PyTeal and Py-algorand-sdk.

The front end application is written with react and vite.

[The repository for the front-end](https://github.com/dspytdao/algo-amm-frontend)

[Website](https://algoamm.com)

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

**NOTE**: This version is using Squads to coordinate chat room creation. The ideal version would work more like the existing chat app, letting you communicate with any urbit without first going through the Squad configuration. 

To chat with your friend, both users must first install Squad and Realtime, then follow these instructions:

1. Use the Squad interface to create a squad. Be sure to give the squad a name, as it seems to cause problems in the interface if it doesn't have one. 
2. The second person should join the Squad. 
3. Launch Realtime, and select the created Squad from the left drop down. 
4. Create a new chat by typing a name for the chat on the left "Chats" section.
5. Click into the chat.
6. The second user should launch realtime, select the Squad, and click into the chat as well.
7. Start typing, the other person can see everything as you type! 

## Limitations

Realtime only supports chat between two users. It's pretty straightforward to increase this number, but the more users the more crowded the screen becomes.

Realtime requires creation of Squads before allowing chat. It would be better to just be able to type the name of a user you want to chat with. 

## App Structure and Explanation

Realtime consists first of the gall agent defined in `realtime.hoon`. This is basically the same as the `%hut` gall agent, with an additional tag on each message: `ephemeral`. Messages marked `ephemeral` are used for the text that is currently being typed, before it is "committed" by pressing enter. 

The second component is the React front-end defined in the `realtime-ui` directory. It lets you choose your squad, choose a chat room, and then send messages. The chat page polls your current input at a set interval (currently 500ms), and sends updates with the `ephemeral` tag set to `"true"`. The chat display filters the messages to only display all the committed (non-ephemeral messages) with the most recent ephemeral message appended at the bottom. As new ephemeral messages come in, they replace the existing text. The result is real-time chat, where you can watch as the person types (albeit jerkily). 

I am the first to acknowledge that this architecture is nearly brain-dead. We're not leveraging hoon code to give special treatment to the ephemeral chats, which really needn't be stored. It would be better to only store the committed messages and the most recent ephemeral message. 

However, this is a result of working in the spirit of a hackathon: when I got in too deep to the hoon code and couldn't get it working quickly enough, I realized that I could just hack around it by leveraging my greater familiarity with the front-end code. My hope is that App School will help me build the skills to avoid this kind of hack and create a more suitable architecture for this app. 

## Future Work: Fluid Real Time Text

The most critical problem with the current solution is that text updates still happen in chunks: a new piece of text arrives with each message, resulting in a "jerky" appearance to the chat. 

When you heard about the polling interval, you might think that it's better to use a shorter interval or even get rid of the interval and send messages in response to keypresses. Unfortunately, not only could this result in spamming the network, neither solution actually resolves the jerkiness problem. 

Ultimately, jitter and latency in the network (which I suspect may be even worse on the urbit network than using something like websockets) will result in some jerkiness or difference between how the person typed and how the text appears on the other persons screen. 

So how would we achieve fluid real time text that preserves the emotions of the original typer over an unstable network? Fortunately, someone has already solved it with a brilliant but elegant solution: Mark Rejhon's (XEP-0301: In-Band Real Time Text)[https://xmpp.org/extensions/xep-0301.html].

Briefly, what that specification describes is a technique for encoding the original intervals between key presses, transmitting them, and then reproducing them at the destination. It treats the text more like a video, using time stamps for each insertion and deletion, and sends a record of those key presses at regular intervals. The result is text appearing on screen that reproduces the the look-and-feel of the typing of the sender, no matter the condition of the network separating the users. 

I believe it is relatively straightforward to adapt the techniques in XEP-0301 for use in a Urbit chat app. 

## Feature Wishlist 

## Useful Resources

[PyTEAL](https://pyteal.readthedocs.io/en/stable/index.html)

[Testnet Dispensary](https://dispenser.testnet.aws.algodev.network/)

[Py-algorand-sdk](https://py-algorand-sdk.readthedocs.io/en/latest/index.html)

[AlgoExplorer](https://testnet.algoexplorer.io/address/)

[Algorand: Build with Python](https://developer.algorand.org/docs/get-started/dapps/pyteal/)

[Alogrand: Smart contract details](https://developer.algorand.org/docs/get-details/dapps/smart-contracts/apps/)

[Amm Demo contract](https://github.com/maks-ivanov/amm-demo/blob/main/amm/contracts/contracts.py)

[Creating Stateful Algorand Smart Contracts in Python with PyTeal](https://developer.algorand.org/articles/creating-stateful-algorand-smart-contracts-python-pyteal/)

[How to publish PIP package](https://shobhitgupta.medium.com/how-to-publish-your-own-pip-package-560bde836b17)