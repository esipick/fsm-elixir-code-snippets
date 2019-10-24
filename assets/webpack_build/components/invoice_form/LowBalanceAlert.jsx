import React, { PureComponent } from 'react';
import Modal from 'react-modal';

const customStyles = {
  content : {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)'
  }
};

class LowBalanceAlert extends PureComponent {
  constructor(props) {
    super(props);

    Modal.setAppElement(document.getElementById('invoice-form'));
  }

  render() {
    const { balance, total } = this.props;

    const card_amount = ((total - balance) / 100).toFixed(2);

    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onClose}
        style={customStyles}
        contentLabel="Insufficient Balance"
      >
        <div className="balance-warning-dialog">
          <div className="balance-warning-dialog__content">
            <div className="balance-warning-dialog__content-disclaimer">
              Balance amount is less than total amount due.
            </div>

            { (balance > 0) &&
                <div>
                  <b>${(balance / 100).toFixed(2)}</b> will be charged from balance and <b>${card_amount}</b> from the card.
                </div> }

            { (balance == 0) &&
                <div>
                  <b>${card_amount}</b> will be charged from the card.
                </div> }
          </div>
          <div className="balance-warning-dialog__controls">
            <button className="btn btn-danger" onClick={this.props.onClose}>
              Cancel
            </button>
            <button className="btn btn-primary" onClick={this.props.onAccept}>
              OK
            </button>
          </div>
        </div>
      </Modal>
    );
  }
};

export default LowBalanceAlert;
