import React, { Component } from 'react'

class CopyLink extends Component {
  handleCopyLink = () => {
    var dummy = document.createElement("input");
    document.body.appendChild(dummy);
    dummy.setAttribute("value", this.props.copy_link);
    dummy.select();

    if (document.execCommand("copy")) {
      $.notify({
        message: this.props.message
      }, {
        type: "success",
        placement: { align: "center" }
      })
    }
    document.body.removeChild(dummy);
  };

  render() {
    return (
      <button
        type= "button"
        className="btn btn-sm btn-primary"
        onClick={this.handleCopyLink}>{this.props.button_text}
      </button>
    );
  }
}

export default CopyLink;
