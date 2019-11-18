import http from 'j-fetch';
import NumericInput from 'react-numeric-input';
import React, { Component } from 'react';
import shortid from 'shortid';

import AsyncSelect from 'react-select/async';
import Select from 'react-select';

import { authHeaders } from '../utils';

export class LineItemRecord {
  constructor() {
    this.id = shortid.generate();
    this.description = DESCRIPTION_OPTS[0].value;
    this.rate = 100;
    this.quantity = 1;
    this.amount = this.rate * this.quantity;
  }
};

const FLIGHT_HOURS = "Flight Hours";
const INSTRUCTOR_HOURS = "Instructor Hours";

const DESCRIPTION_OPTS = [
  FLIGHT_HOURS,
  INSTRUCTOR_HOURS,
  "Fuel Charge",
  "Fuel Reimbursement",
  "Equipment Rental"
].map(o => ({ label: o, value: o }));

class InvoiceLineItem extends Component {
  constructor(props) {
    super(props);

    this.state = {
      item: props.item
    }
  }

  setDesc = (option) => {
    const item = Object.assign({}, this.state.item, { description: option.value });

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

  loadInstructors = (input, callback) => {
    this.setState({ instructors_loading: true });

    http.get({
        url: '/api/users/autocomplete?role=instructor&name=' + input,
        headers: authHeaders()
      }).then(r => r.json())
      .then(r => {
        callback(r.data);
        this.setState({ instructors_loading: false });
      })
      .catch(err => {
        err.json().then(e => {
          callback([]);
          this.setState({ instructors_loading: false });
        })
      });
  }

  setInstructor = (instructor) => {
    const item = Object.assign({}, this.state.item, { rate: instructor.billing_rate });
    this.setState({ instructor, item });
  }

  instructorSelect = () => {
    const { instructors_loading, instructor } = this.state;

    return (
      <AsyncSelect placeholder="Instructor name"
        classNamePrefix="react-select"
        loadOptions={this.loadInstructors}
        onChange={this.setInstructor}
        isLoading={instructors_loading}
        getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
        getOptionValue ={(o) => o.id}
        value={instructor} />
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
