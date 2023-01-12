import React, { Component } from 'react';

class Messages extends Component {

  render() {
    const { msgJar, bottom, patpShorten, currentHut, filterUser } = this.props;
    const msgs = msgJar.has(currentHut) ? msgJar.get(currentHut) : [];
    const msgsFromUser= msgs.filter(msg => msg.who === filterUser);
    const lastEphemeral = msgsFromUser.findLast(msg => msg.ephemeral === "true");
    const msgsNonEphemeral = msgsFromUser.filter(msg => msg.ephemeral !== "true");
    const msgsDisplay = lastEphemeral != null ? msgsNonEphemeral.concat([lastEphemeral]) : msgsNonEphemeral;
    return (
      <div className="msgs">
        <div className="fix"/>
        {
          msgsDisplay.map((msg, ind) =>
            <p className="msg" key={ind}>
              <span className="who">
                {patpShorten(msg.who) + '>'}
              </span>
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
