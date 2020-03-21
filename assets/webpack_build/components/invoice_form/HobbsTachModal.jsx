import classnames from 'classnames';
import http from 'j-fetch';
import Modal from 'react-modal';
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';

import { authHeaders, addSchoolIdParam } from '../utils';

import Error from '../common/Error';
import { modalStyles } from './LowBalanceAlert';

const MAX_INT = 2147483647;

class HobbsTachModal extends Component {
  constructor(props) {
    super(props);

    const { aircraft, values: { hobbs_start, hobbs_end, tach_start, tach_end } } = props;

    this.state = {
      hobbs_start,
      hobbs_end,
      tach_start,
      tach_end,
      errors: {},
      saving: false
    }

    Modal.setAppElement(document.getElementById('invoice-form'));
  }

  setHobbsStart = ({ value = 0 }) => {
    const hobbs_start = value >= MAX_INT ? this.state.hobbs_start : value;

    this.setState({ hobbs_start });
  }

  setHobbsEnd = ({ value = 0 }) => {
    const hobbs_end = value >= MAX_INT ? this.state.hobbs_end : value;

    this.setState({ hobbs_end });
  }

  setTachStart = ({ value = 0 }) => {
    const tach_start = value >= MAX_INT ? this.state.tach_start : value;

    this.setState({ tach_start });
  }

  setTachEnd = ({ value = 0 }) => {
    const tach_end = value >= MAX_INT ? this.state.tach_end : value;

    this.setState({ tach_end });
  }

  calculate = () => {
    const { hobbs_start, hobbs_end, tach_start, tach_end } = this.state;
    const errors = {};
    if (hobbs_end <= hobbs_start) {
      errors.hobbs_end = "must be greater than hobbs start";
    }
    if (tach_end <= tach_start) {
      errors.tach_end = "must be greater than tach start";
    }

    this.setState({ errors });

    if (Object.keys(errors).length) return;

    if (this.state.saving) return;
    this.setState({ saving: true });

    const payload = {
      aircraft_details: {
        aircraft_id: this.props.aircraft.id,
        hobbs_start,
        hobbs_end,
        tach_start,
        tach_end
      },
      creator_user_id: this.props.creator.id,
      user_id: this.props.creator.id
    };

    http.post({
      url: '/api/transactions/preview?' + addSchoolIdParam(),
      body: { detailed: payload },
      headers: authHeaders()
    }).then(response => {
      response.json().then(({ data }) => {
        this.setState({ saving: false }, () => {
          this.props.onAccept({
            hobbs_start,
            hobbs_end,
            tach_start,
            tach_end,
            amount: data.total
          });
        });
      });
    }).catch(response => {
      response.json().then((err) => {
        console.warn(err);
        const { aircraft_details: { hobbs_start, hobbs_end, tach_start, tach_end } } = err.errors;
        const errors = { hobbs_start, hobbs_end, tach_start, tach_end };
        this.setState({ saving: false, errors });
      });
    });
  }

  render() {
    const { hobbs_start, hobbs_end, tach_start, tach_end, errors } = this.state;

    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onClose}
        style={modalStyles}
        contentLabel="Enter Hobbs & Tach Time"
      >
        <div className="hobbs-and-tach-dialog">
          <div className="hobbs-and-tach-dialog__content">
            <h5 className="hobbs-and-tach-dialog__content-disclaimer">
              Enter Hobbs & Tach Time
            </h5>

            <div className="row my-1">
              <label className="col-md-5 col-form-label text-left">Hobbs Start *</label>
              <div className="col-md-7">
                <NumberFormat allowNegative={false}
                  className="form-control inherit-font-size"
                  decimalScale={0}
                  fixedDecimalScale={0}
                  onValueChange={this.setHobbsStart}
                  required={true}
                  thousandSeparator={true}
                  value={hobbs_start} />
                <Error text={errors.hobbs_start} className="hobbs-and-tach-dialog__error" />
              </div>
            </div>
            <div className="row my-1">
              <label className="col-md-5 col-form-label text-left">Hobbs End *</label>
              <div className="col-md-7">
                <NumberFormat allowNegative={false}
                  className="form-control inherit-font-size"
                  decimalScale={0}
                  fixedDecimalScale={0}
                  onValueChange={this.setHobbsEnd}
                  required={true}
                  thousandSeparator={true}
                  value={hobbs_end} />
                <Error text={errors.hobbs_end} className="hobbs-and-tach-dialog__error" />
              </div>
            </div>
            <div className="row my-1">
              <label className="col-md-5 col-form-label text-left">Tach Start *</label>
              <div className="col-md-7">
                <NumberFormat allowNegative={false}
                  className="form-control inherit-font-size"
                  decimalScale={0}
                  fixedDecimalScale={0}
                  onValueChange={this.setTachStart}
                  required={true}
                  thousandSeparator={true}
                  value={tach_start} />
                <Error text={errors.tach_start} className="hobbs-and-tach-dialog__error" />
              </div>
            </div>
            <div className="row my-1">
              <label className="col-md-5 col-form-label text-left">Tach End *</label>
              <div className="col-md-7">
                <NumberFormat allowNegative={false}
                  className="form-control inherit-font-size"
                  decimalScale={0}
                  fixedDecimalScale={0}
                  onValueChange={this.setTachEnd}
                  required={true}
                  thousandSeparator={true}
                  value={tach_end} />
                <Error text={errors.tach_end} className="hobbs-and-tach-dialog__error" />
              </div>
            </div>

            <Error text={errors.base} className="hobbs-and-tach-dialog__error" />

          </div>
          <div className="hobbs-and-tach-dialog__controls">
            <button className="btn btn-danger" onClick={this.props.onClose}>
              Cancel
            </button>
            <button className="btn btn-primary" onClick={this.calculate}>
              Calculate Amount
            </button>
          </div>
        </div>
      </Modal>
    );
  }
}

export default HobbsTachModal;
