import React, { Component } from 'react';

class Messages extends Component {

  render() {
    const { msgJar, bottom, patpShorten, currentHut, filterUser } = this.props;
    const msgs = msgJar.has(currentHut) ? msgJar.get(currentHut) : [];
    const msgsFiltered = msgs.filter(msg => msg.who === filterUser);
    return (
      <div className="msgs">
        <div className="fix"/>
        {
          msgsFiltered.map((msg, ind) =>
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
