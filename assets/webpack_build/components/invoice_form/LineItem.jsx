import http from 'j-fetch';
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';

import Error from '../common/Error';
import Select from 'react-select';

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
      line_item
    }
  }

  setDesc = (option) => {
    const line_item = Object.assign({}, this.state.line_item, {
      description: option.value,
      rate: option.rate || DEFAULT_RATE,
      type: TYPES[option.value] || DEFAULT_TYPE
    });

    this.setState({ line_item });
    this.props.onChange(line_item);
  }

  setRate = ({ floatValue = 0 }) => {
    const rate = floatValue >= 10000 ? 9999 : floatValue;
    const line_item = Object.assign({}, this.state.line_item, { rate: rate * 100 });

    this.calculateAmount(line_item);
  }

  setQty = ({ floatValue = 0 }) => {
    const quantity = floatValue >= 1000 ? this.state.line_item.quantity : floatValue;
    const line_item = Object.assign({}, this.state.line_item, { quantity });

    this.calculateAmount(line_item);
  }

  calculateAmount = (line_item) => {
    line_item.amount = (line_item.rate * line_item.quantity);

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

  setAircraft = (aircraft) => {
    const rate = aircraft ? aircraft.rate_per_hour : DEFAULT_RATE;
    const aircraft_id = aircraft ? aircraft.id : null;
    const amount = rate * this.state.line_item.quantity;
    const payload = { rate, aircraft_id, amount };
    const line_item = Object.assign({}, this.state.line_item, payload);

    this.setState({ aircraft, line_item });
    this.props.onChange(line_item);
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
        <Error text={errors.aircraft_id} styleProps={{ position: 'absolute' }} />
      </div>
    );
  }

  selectOptions = () => {
    let options = DESCRIPTION_OPTS.concat(this.props.custom_line_items.map(o => ({
      label: o.description,
      rate: o.default_rate,
      value: o.description
    })))

    for (let line_item of this.props.line_items) {
      if (!options.find(o => o.value == line_item.description)) {
        options = options.concat({
          label: line_item.description,
          rate: line_item.rate,
          value: line_item.description
        })
      }
    }

    return options
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
        <Error text={errors.instructor_user_id} styleProps={{ position: 'absolute' }} />
      </div>
    );
  }

  render() {
    const { line_item: { id, description, rate, quantity, amount } } = this.state;
    const { number, canRemove, errors } = this.props;
    const options = this.selectOptions()
    const descriptionOpt = options.find(o => o.value == description);
    const wrapperClass = Object.keys(this.props.errors).length ? 'lc-row-with-error' : '';

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
        <td className="lc-column">
          <NumberFormat allowNegative={true}
            className="form-control inherit-font-size"
            decimalScale={2}
            fixedDecimalScale={2}
            onValueChange={this.setRate}
            required={true}
            thousandSeparator={true}
            value={rate / 100} />
          <Error text={errors.rate} styleProps={{ position: 'absolute' }} />
        </td>
        <td className="lc-column">
          <NumberFormat allowNegative={false}
            className="form-control inherit-font-size"
            decimalScale={2}
            fixedDecimalScale={2}
            onValueChange={this.setQty}
            required={true}
            thousandSeparator={true}
            value={quantity} />
          <Error text={errors.quantity} styleProps={{ position: 'absolute' }} />
        </td>
        <td className="lc-column">${(amount / 100).toFixed(2)}</td>
        <td className="lc-column remove-line-item-wrapper">
          {canRemove && <a className="remove-line-item" href="" onClick={this.remove}>&times;</a>}
        </td>
      </tr>
    )
  }
}

export default InvoiceLineItem;
