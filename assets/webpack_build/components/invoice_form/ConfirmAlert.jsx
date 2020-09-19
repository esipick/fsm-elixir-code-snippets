import React, { PureComponent } from 'react';
import Modal from 'react-modal';

import { modalStyles } from './constants';

class ConfirmAlert extends PureComponent {
  constructor(props) {
    super(props);

    Modal.setAppElement(document.getElementById('invoice-form'));
  }

  render() {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onClose}
        style={modalStyles}
        contentLabel="Error">
        <div className="balance-warning-dialog">
          <div className="balance-warning-dialog__content">
            <h5 className="balance-warning-dialog__content-disclaimer">
              Cancel Invoice?
            </h5>

            {this.props.text}
          </div>
          <div className="balance-warning-dialog__controls">
            <button className="btn btn-danger" onClick={this.props.onReject}>
              NO
            </button>
            <button className="btn btn-primary" onClick={this.props.onAccept}>
              YES
            </button>
          </div>
        </div>
      </Modal>
    );
  }
};

export default ConfirmAlert;
