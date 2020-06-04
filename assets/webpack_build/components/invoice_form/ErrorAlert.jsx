import React, { PureComponent } from 'react';
import Modal from 'react-modal';

import { modalStyles } from './constants';

class ErrorAlert extends PureComponent {
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
              Error!
            </h5>

            {this.props.text}
          </div>
          <div className="balance-warning-dialog__controls">
            <button className="btn btn-primary" onClick={this.props.onAccept}>
              OK
            </button>
          </div>
        </div>
      </Modal>
    );
  }
};

export default ErrorAlert;
