import React, { Component } from 'react';

class People extends Component {

  handleClick = () => {
    (this.props.currentGid !== null) &&
      (this.props.currentGid.split("/")[0] === this.props.our)
      ? (this.props.currentHut !== null) && this.props.deleteHut()
      : this.props.leaveGid()
  };

  render() {
    const { joined, currentGid, currentHut, our, leaveGid} = this.props;
    const ppl = (currentGid === null)
          ? []
          : (joined.has(currentGid))
          ? [...joined.get(currentGid)]
          : [];
    return (
      (currentGid !== null ) &&
        <div className="right-menu">
          {
            (currentGid !== null)
              && (currentGid.split("/")[0] === our)
              && (currentHut !== null)
              && <button
                   className="leave-button"
                   onClick={
                     () => (window.confirm('Are you sure?'))
                       && this.handleClick()
                   }
                 >
                   Delete
                 </button>
          }
          {
            (currentGid !== null)
              && (currentGid.split("/")[0] !== our)
              && <button
                   className="leave-button"
                   onClick={
                     () => (window.confirm('Are you sure?'))
                       && this.handleClick()
                   }
                 >
                   Leave
                 </button>

          }
          {
            (currentGid !== null) &&
              <div className="ppl">
                <div className="font-semibold text-wall-400">People</div>
                {
                  Array.from(ppl, ship =>
                    <div key={ship}>
                      {this.props.patpShorten(ship)}
                    </div>
                  )
                }
              </div>
          }
        </div>
    )
  }
};

export default People;
