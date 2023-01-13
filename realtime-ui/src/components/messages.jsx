import React, { Component } from 'react';

class Messages extends Component {

  render() {
    const { msgJar, bottom, currentHut, filterUser, showEphemeral} = this.props;
    const msgs = msgJar.has(currentHut) ? msgJar.get(currentHut) : [];
    const msgsFromUser= msgs.filter(msg => msg.who === filterUser);
    const lastEphemeral = msgsFromUser.findLast(msg => msg.ephemeral === "true");
    const msgsNonEphemeral = msgsFromUser.filter(msg => msg.ephemeral !== "true");
    let msgsDisplay = msgsNonEphemeral;
    if (showEphemeral && lastEphemeral != null) {
      const lastMessage = msgsNonEphemeral[msgsNonEphemeral.length - 1];
      // This prevents ghosting of the last ephemeral message
      if (lastMessage != null && lastEphemeral.what !== lastMessage.what) {
        msgsDisplay = msgsNonEphemeral.concat([lastEphemeral]);
      }
    }
    return (
      <div className="msgs">
        <div className="fix"/>
        {
          msgsDisplay.map((msg, ind) =>
            <p className="msg" key={ind}>
              <span className="what" lang="en">{msg.what}</span>
            </p>
          )
        }
        <div ref={bottom} />
      </div>
    )
  }
};

export default Messages;
