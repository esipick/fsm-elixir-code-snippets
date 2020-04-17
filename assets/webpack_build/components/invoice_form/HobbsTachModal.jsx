import classnames from 'classnames';
import http from 'j-fetch';
import Modal from 'react-modal';
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';

import { authHeaders, addSchoolIdParam } from '../utils';

import Error from '../common/Error';
import { modalStyles } from './LowBalanceAlert';

const MAX_INT = 2147483647;

const NUMBER_PROPS = {
  allowNegative: false,
  className: "form-control inherit-font-size",
  decimalScale: 1,
  fixedDecimalScale: 1,
  required: true,
  thousandSeparator: true
};

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

  componentDidUpdate(prevProps, _prevState, _snapshot) {
    const { student, aircraft } = this.props;
    const prevStudent = prevProps.student;

    if ((student && student.id) !== (prevStudent && prevStudent.id)) {
      this.calculate();
    }

    let newState = {};

    if (this.props.open && !prevProps.open) newState.errors = {};
    if ((aircraft && aircraft.id) !== (prevProps.aircraft && prevProps.aircraft.id)) {
      newState = Object.assign(newState, this.props.values);
    }

    if (Object.keys(newState).length) this.setState(newState);
  }

  setHobbsStart = ({ floatValue = 0 }) => {
    const hobbs_start = floatValue >= MAX_INT ? this.state.hobbs_start : floatValue * 10;

    this.setState({ hobbs_start });
  }

  setHobbsEnd = ({ floatValue = 0 }) => {
    const hobbs_end = floatValue >= MAX_INT ? this.state.hobbs_end : floatValue * 10;

    this.setState({ hobbs_end });
  }

  setTachStart = ({ floatValue = 0 }) => {
    const tach_start = floatValue >= MAX_INT ? this.state.tach_start : floatValue * 10;

    this.setState({ tach_start });
  }

  setTachEnd = ({ floatValue = 0 }) => {
    const tach_end = floatValue >= MAX_INT ? this.state.tach_end : floatValue * 10;

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

    const { student, creator } = this.props;

    const payload = {
      aircraft_details: {
        aircraft_id: this.props.aircraft && this.props.aircraft.id,
        hobbs_start,
        hobbs_end,
        tach_start,
        tach_end
      },
      creator_user_id: creator.id,
      user_id: student && student.id || creator.id
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

        const aircraft_details = err.errors.aircraft_details || {};
        const { hobbs_start, hobbs_end, tach_start, tach_end } = aircraft_details;
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
                <NumberFormat {...NUMBER_PROPS}
                  onValueChange={this.setHobbsStart}
                  value={hobbs_start / 10} />
                <Error text={errors.hobbs_start} className="hobbs-and-tach-dialog__error" />
              </div>
            </div>
            <div className="row my-1">
              <label className="col-md-5 col-form-label text-left">Hobbs End *</label>
              <div className="col-md-7">
                <NumberFormat {...NUMBER_PROPS}
                  onValueChange={this.setHobbsEnd}
                  value={hobbs_end / 10} />
                <Error text={errors.hobbs_end} className="hobbs-and-tach-dialog__error" />
              </div>
            </div>
            <div className="row my-1">
              <label className="col-md-5 col-form-label text-left">Tach Start *</label>
              <div className="col-md-7">
                <NumberFormat {...NUMBER_PROPS}
                  onValueChange={this.setTachStart}
                  value={tach_start / 10} />
                <Error text={errors.tach_start} className="hobbs-and-tach-dialog__error" />
              </div>
            </div>
            <div className="row my-1">
              <label className="col-md-5 col-form-label text-left">Tach End *</label>
              <div className="col-md-7">
                <NumberFormat {...NUMBER_PROPS}
                  onValueChange={this.setTachEnd}
                  value={tach_end / 10} />
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
