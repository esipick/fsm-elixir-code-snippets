import http from 'j-fetch';
import NumericInput from 'react-numeric-input';
import React, { Component } from 'react';

import Select from 'react-select';

import {
  LineItemRecord, FLIGHT_HOURS, INSTRUCTOR_HOURS, DEFAULT_TYPE, TYPES, DESCRIPTION_OPTS, DEFAULT_RATE
} from './line_item_utils';
import { authHeaders } from '../utils';

class InvoiceLineItem extends Component {
  constructor(props) {
    super(props);

    const { item } = props;
    const { aircraft, instructor_user } = item;

    this.state = {
      item: props.item,
      instructor_user,
      aircraft
    }
  }

  setDesc = (option) => {
    const item = Object.assign({}, this.state.item, {
      description: option.value,
      type: TYPES[option.value] || DEFAULT_TYPE
    });

    this.setState({ item });
    this.props.onChange(item);
  }

  setRate = (e) => {
    const item = Object.assign({}, this.state.item, { rate: e * 100 });

    this.calculateAmount(item);
  }

  setQty = (quantity) => {
    const item = Object.assign({}, this.state.item, { quantity });

    this.calculateAmount(item);
  }

  calculateAmount = (item) => {
    item.amount = (item.rate * item.quantity);

    this.setState({ item });
    this.props.onChange(item);
  }

  remove = (e) => {
    e.preventDefault();

    this.props.onRemove(this.state.item.id);
  }

  isFlightHours = () => {
    return this.state.item.description == FLIGHT_HOURS;
  }

  isInstructorHours = () => {
    return this.state.item.description == INSTRUCTOR_HOURS;
  }

  setAircraft = (aircraft) => {
    const payload = aircraft ? {
        rate: aircraft.rate_per_hour,
        aircraft_id: aircraft.id
      } : {
        aircraft_id: null,
        rate: DEFAULT_RATE
      };

    const item = Object.assign({}, this.state.item, payload);
    this.setState({ aircraft, item });
    this.props.onChange(item);
  }

  aircraftSelect = () => {
    const { aircrafts_loading, aircraft } = this.state;

    return (
      <Select placeholder="Tail #"
        classNamePrefix="react-select"
        options={this.props.aircrafts}
        onChange={this.setAircraft}
        isClearable={true}
        getOptionLabel={(o) => o.tail_number}
        getOptionValue ={(o) => o.id}
        value={aircraft} />
    );
  }

  setInstructor = (instructor_user) => {
    const payload = instructor_user ? {
        rate: instructor_user.billing_rate,
        instructor_user_id: instructor_user.id
      } : {
        instructor_user_id: null,
        rate: DEFAULT_RATE
      };

    const item = Object.assign({}, this.state.item, payload);
    this.setState({ instructor_user, item });
    this.props.onChange(item);
  }

  instructorSelect = () => {
    const { instructors_loading, instructor_user } = this.state;

    return (
      <Select placeholder="Instructor name"
        classNamePrefix="react-select"
        options={this.props.instructors}
        onChange={this.setInstructor}
        isClearable={true}
        getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
        getOptionValue ={(o) => o.id}
        value={instructor_user} />
    );
  }

  render() {
    const { item: { id, description, rate, quantity, amount } } = this.state;
    const { number, canRemove } = this.props;
    const descriptionOpt = DESCRIPTION_OPTS.find(o => o.value == description);

    return (
      <tr key={id}>
        <td>{number}.</td>
        <td className="lc-desc-column">
          <Select
            name="description"
            classNamePrefix="react-select"
            options={DESCRIPTION_OPTS}
            defaultValue={descriptionOpt}
            onChange={this.setDesc}
            isSearchable={false}
            isClearable={false}
            isRtl={false}
            required={true} />
        </td>
        <td className="lc-desc-column">
          { this.isInstructorHours() && this.instructorSelect()}
          { this.isFlightHours() && this.aircraftSelect()}
        </td>
        <td className="lc-column">
          <NumericInput precision={2}
            value={rate / 100}
            className="form-control"
            step={0.1}
            onChange={this.setRate}
            required={true} />
        </td>
        <td className="lc-column">
          <NumericInput precision={2}
            value={quantity}
            className="form-control"
            step={0.1}
            onChange={this.setQty}
            required={true} />
        </td>
        <td className="lc-column">${(amount / 100).toFixed(2)}</td>
        <td className="lc-column remove-line-item-wrapper">
          { canRemove && <a className="remove-line-item" href="" onClick={this.remove}>&times;</a> }
        </td>
      </tr>
    )
  }
}

export default InvoiceLineItem;
