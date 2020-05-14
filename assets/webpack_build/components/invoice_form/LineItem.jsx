import classnames from 'classnames';
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';
import Select from 'react-select';

import HobbsTachModal from './HobbsTachModal';

import Error from '../common/Error';

import {
  LineItemRecord, FLIGHT_HOURS, INSTRUCTOR_HOURS, DEFAULT_TYPE, TYPES, DESCRIPTION_OPTS, DEFAULT_RATE
} from './line_item_utils';
import { authHeaders } from '../utils';

class InvoiceLineItem extends Component {
  constructor(props) {
    super(props);

    const { line_item } = props;
    const { aircraft, instructor_user } = line_item;

    this.state = {
      aircraft,
      instructor_user,
      line_item,
      hobbs_and_tach_mode: false
    }
  }

  setDesc = (option) => {
    const line_item = Object.assign({}, this.state.line_item, {
      description: option.value,
      rate: option.rate || DEFAULT_RATE,
      type: TYPES[option.value] || DEFAULT_TYPE,
      taxable: option.taxable,
      deductible: option.deductible
    });

    this.setState({ line_item });
    this.props.onChange(line_item);
  }

  setRate = ({ floatValue }) => {
    const rate = floatValue == null ? 0 : floatValue;
    let line_item = Object.assign({}, this.state.line_item, { rate: rate * 100});

    this.calculateAmount(line_item);

    if (floatValue == null) {
      line_item.rate = null;
      this.setState({ line_item })
    }
  }

  setQty = ({ floatValue }) => {
    const quantity = floatValue == null ? 0 : floatValue;
    let line_item = Object.assign({}, this.state.line_item, { quantity: quantity });

    this.calculateAmount(line_item);

    if (floatValue == null) {
      line_item.quantity = null;
      this.setState({ line_item })
    }
  }

  calculateAmount = (line_item) => {
    line_item.amount = (line_item.rate * line_item.quantity);

    this.setState({ line_item });
    this.props.onChange(line_item);
  }

  applyHobbsAndTach = (data) => {
    const { hobbs_start, hobbs_end, tach_start, tach_end, amount } = data;

    const line_item = Object.assign({}, this.state.line_item, {
      hobbs_start,
      hobbs_end,
      tach_start,
      tach_end,
      quantity: 1,
      rate: amount,
      amount: amount,
      hobbs_tach_used: true
    });

    this.setState({ line_item, hobbs_and_tach_mode: false });
    this.props.onChange(line_item);
  }

  resetHobbsAndTach = (e) => {
    e && e.preventDefault();

    const line_item = Object.assign({}, this.state.line_item, {
      hobbs_start: null,
      hobbs_end: null,
      tach_start: null,
      tach_end: null,
      hobbs_tach_used: false
    });

    this.setState({ line_item });
    this.props.onChange(line_item);
  }

  remove = (e) => {
    e.preventDefault();

    this.props.onRemove(this.state.line_item.id);
  }

  isFlightHours = () => {
    return this.state.line_item.description == FLIGHT_HOURS;
  }

  isInstructorHours = () => {
    return this.state.line_item.description == INSTRUCTOR_HOURS;
  }

  isHobbsAndTach = () => (this.isFlightHours() && this.state.hobbs_and_tach_mode);

  setAircraft = (aircraft) => {
    const rate = aircraft ? aircraft.rate_per_hour : DEFAULT_RATE;
    const aircraft_id = aircraft ? aircraft.id : null;
    const amount = rate * this.state.line_item.quantity;
    const payload = { rate, aircraft_id, amount };
    const line_item = Object.assign({}, this.state.line_item, payload);

    this.setState({ aircraft, line_item }, () => this.resetHobbsAndTach());
  }

  aircraftSelect = () => {
    const { errors } = this.props;
    const { aircrafts_loading, aircraft } = this.state;

    return (
      <div>
        <Select classNamePrefix="react-select"
          getOptionLabel={(o) => o.tail_number}
          getOptionValue={(o) => o.id}
          isClearable={true}
          onChange={this.setAircraft}
          options={this.props.aircrafts}
          placeholder="Tail #"
          value={aircraft} />
        <Error text={errors.aircraft_id} />
      </div>
    );
  }

  selectOptions = () => {
    const options = DESCRIPTION_OPTS.concat(this.props.custom_line_items.map(o => ({
      label: o.description,
      rate: o.default_rate,
      value: o.description,
      taxable: o.taxable,
      deductible: o.deductible
    })))

    const additionalOptions = this.props.line_items.filter(line_item => (
      !options.find(o => o.value == line_item.description)
    )).map(line_item => ({
      label: line_item.description,
      rate: line_item.rate,
      value: line_item.description,
      taxable: line_item.taxable,
      deductible: line_item.deductible
    }));

    return [...options, ...additionalOptions];
  }

  setInstructor = (instructor_user) => {
    const rate = instructor_user ? instructor_user.billing_rate : DEFAULT_RATE;
    const instructor_user_id = instructor_user ? instructor_user.id : null;
    const amount = rate * this.state.line_item.quantity;
    const payload = { rate, instructor_user_id, amount };
    const line_item = Object.assign({}, this.state.line_item, payload);

    this.setState({ instructor_user, line_item });
    this.props.onChange(line_item);
  }

  instructorSelect = () => {
    const { errors } = this.props;
    const { instructors_loading, instructor_user } = this.state;

    return (
      <div>
        <Select classNamePrefix="react-select"
          getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
          getOptionValue={(o) => o.id}
          isClearable={true}
          onChange={this.setInstructor}
          options={this.props.instructors}
          value={instructor_user}
          placeholder="Instructor name" />
        <Error text={errors.instructor_user_id} />
      </div>
    );
  }

  toggleHobbsAndTach = (e) => {
    e.preventDefault();

    if (!this.isFlightHours() || !this.state.aircraft) return;

    const hobbs_and_tach_mode = !this.state.hobbs_and_tach_mode;

    this.setState({ hobbs_and_tach_mode });
  }

  flightModeToggler = () => {
    const { aircraft } = this.state;
    const klassName = aircraft ? '' : 'hobbs-tach-icon-disabled';

    return (
      <a className={klassName} onClick={this.toggleHobbsAndTach} title="Use Hobbs and Tach time" href="#">
        <i className="now-ui-icons tech_watch-time"></i>
      </a>
    )
  }

  standardFields = () => {
    const { line_item: { rate, quantity, deductible } } = this.state;
    const { errors } = this.props;
    const rateClass = classnames(
      'form-control inherit-font-size',
      this.isFlightHours() ? 'aircraft-rate-control' : '',
      deductible ? 'deductible' : ''
    );

    return (
      <React.Fragment>
        <td className="lc-column">
          { this.isFlightHours() && this.flightModeToggler() }
          <NumberFormat allowNegative={false}
            className={rateClass}
            decimalScale={2}
            fixedDecimalScale={2}
            onValueChange={this.setRate}
            required={true}
            placeholder="0.00"
            thousandSeparator={true}
            value={rate == null ? null : rate / 100 } />
          { errors.rate && <br /> }
          <Error text={errors.rate} />
        </td>
        <td className="lc-column">
          <NumberFormat allowNegative={false}
            className="form-control inherit-font-size"
            decimalScale={2}
            fixedDecimalScale={2}
            onValueChange={this.setQty}
            required={true}
            placeholder="0.00"
            thousandSeparator={true}
            value={quantity} />
          <Error text={errors.quantity} />
        </td>
      </React.Fragment>
    )
  }

  hobbsAndTachFields = () => {
    return (
      <React.Fragment>
        <td className="lc-column" colSpan={2}>
          Calculated using Hobbs & Tach time.
          <a className="ml-1" onClick={this.toggleHobbsAndTach} href="#">Edit</a>
          <a className="ml-1" onClick={this.resetHobbsAndTach} href="#">Clear</a>
        </td>
      </React.Fragment>
    );
  }

  hobbsAndTachModal = () => {
    const { aircraft, line_item } = this.state;

    const hobbs_start = line_item.hobbs_start || aircraft && aircraft.last_hobbs_time || 0;
    const hobbs_end = line_item.hobbs_end || 0;
    const tach_start = line_item.tach_start || aircraft && aircraft.last_tach_time || 0;
    const tach_end = line_item.tach_end || 0;
    const values = { hobbs_start, hobbs_end, tach_start, tach_end };

    return (
      <HobbsTachModal aircraft={aircraft}
        values={values}
        open={this.isHobbsAndTach()}
        student={this.props.student}
        creator={this.props.creator}
        onClose={this.toggleHobbsAndTach}
        onAccept={this.applyHobbsAndTach} />
    )
  }

  render() {
    const { aircraft, line_item: { hobbs_tach_used, id, description, amount, deductible } } = this.state;
    const { number, canRemove, errors } = this.props;
    const options = this.selectOptions()
    const descriptionOpt = options.find(o => o.value == description);
    const wrapperClass = Object.keys(this.props.errors).length ? 'lc-row-with-error' : '';
    const amountCss = classnames('lc-column', deductible ? 'deductible' : '');

    return (
      <tr key={id} className={wrapperClass}>
        <td>{number}.</td>
        <td className="lc-desc-column">
          <Select classNamePrefix="react-select"
            defaultValue={descriptionOpt}
            isClearable={false}
            isRtl={false}
            isSearchable={false}
            name="description"
            onChange={this.setDesc}
            options={options}
            required={true} />
        </td>
        <td className="lc-desc-column">
          {this.isInstructorHours() && this.instructorSelect()}
          {this.isFlightHours() && this.aircraftSelect()}
        </td>
        { this.isFlightHours() && this.hobbsAndTachModal() }
        { !hobbs_tach_used && this.standardFields() }
        { hobbs_tach_used && this.hobbsAndTachFields() }
        <td className={amountCss}>${(amount / 100).toFixed(2)}</td>
        <td className="lc-column remove-line-item-wrapper">
          {canRemove && <a className="remove-line-item" href="" onClick={this.remove}>&times;</a>}
        </td>
      </tr>
    )
  }
}

export default InvoiceLineItem;
