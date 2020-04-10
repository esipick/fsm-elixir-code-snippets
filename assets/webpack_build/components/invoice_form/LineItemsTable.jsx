import React, { Component } from 'react';
import http from 'j-fetch';
import LineItem from './LineItem';

import { itemsFromAppointment, LineItemRecord } from './line_item_utils';

import { authHeaders, addSchoolIdParam } from '../utils';

const lineItemsKey = (appointment) => appointment && appointment.id || 'none';

class LineItemsTable extends Component {
  constructor(props) {
    super(props);

    const { appointment } = props;
    const line_items =
      props.line_items.length > 0 ? props.line_items : itemsFromAppointment(appointment);

    const memo = {
      [lineItemsKey(appointment)]: line_items
    }

    this.state = { memo, appointment };
  }

  componentDidMount = () => {
    this.updateTotal(this.lineItems());
  }

  componentDidUpdate = () => {
    this.calculateTotal(this.lineItems(), ({ total_amount_due }) => {
      if (total_amount_due !== this.state.total_amount_due) {
        this.updateTotal(this.lineItems());
      }
    });
  }

  static getDerivedStateFromProps(props, state) {
    const prevAppointmentId = state.appointment && state.appointment.id;
    const appointmentId = props.appointment && props.appointment.id;

    if (prevAppointmentId !== appointmentId) {
      const { memo } = state;
      const { appointment } = props;
      const key = lineItemsKey(appointment);

      if (!memo[key]) { memo[key] = itemsFromAppointment(appointment); };

      return { ...state, memo, appointment };
    }

    return null;
  }

  lineItems = () => {
    const key = lineItemsKey(this.state.appointment);

    return this.state.memo[key];
  }

  addLineItem = () => {
    const line_items = [...this.lineItems(), new LineItemRecord()];
    this.updateTotal(line_items);
  }

  removeLineItem = (id) => {
    const line_items = this.lineItems().filter(i => i.id != id);
    this.updateTotal(line_items);
  }

  setLineItem = (item) => {
    const line_items = this.lineItems().map(i => i.id == item.id ? item : i);
    this.updateTotal(line_items);
  };

  calculateTotal = (line_items, callback) => {
    const { student, appointment } = this.props;

    const payload = {
      line_items,
      user_id: student && student.id,
      appointment_id: appointment && appointment.id
    }

    http.post({
      url: '/api/invoices/calculate?' + addSchoolIdParam(),
      body: { invoice: payload },
      headers: authHeaders()
    }).then(response => {
      response.json().then(callback);
    }).catch(response => {
      response.json().then((err) => {
        console.warn(err);
      });
    });
  }

  updateTotal = (line_items) => {
    this.calculateTotal(line_items, (values) => {
      const { memo } = this.state;

      memo[lineItemsKey(this.state.appointment)] = values.line_items;

      this.setState({ ...values, memo });
      this.props.onChange(values);
    });
  }

  render() {
    const { total, total_tax, total_amount_due } = this.state;
    const { aircrafts, custom_line_items, errors, instructors, sales_tax } = this.props;
    const line_items = this.lineItems();

    return (
      <table className="table table-striped line-items-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Description</th>
            <th></th>
            <th>Rate</th>
            <th>Qty/Hours</th>
            <th>Amount $</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {
            line_items.map((line_item, i) => (
              <LineItem aircrafts={aircrafts}
                canRemove={line_items.length > 1}
                custom_line_items={custom_line_items}
                student={this.props.student}
                creator={this.props.creator}
                errors={errors[i] || {}}
                instructors={instructors}
                key={line_item.id || i}
                line_item={line_item}
                line_items={line_items}
                number={i + 1}
                onChange={this.setLineItem}
                onRemove={this.removeLineItem} />
            ))
          }
          <tr>
            <td colSpan="7">
              <button className="btn btn-sm btn-default" onClick={this.addLineItem}>Add</button>
            </td>
          </tr>
          <tr>
            <td colSpan="5" className="text-right">
              Total excl. taxes:
            </td>
            <td colSpan="2">${(total / 100).toFixed(2)}</td>
          </tr>
          <tr>
            <td colSpan="5" className="text-right">
              Sales Tax %:
            </td>
            <td colSpan="2">{sales_tax}</td>
          </tr>
          <tr>
            <td colSpan="5" className="text-right">
              Total tax:
            </td>
            <td colSpan="2">${(total_tax / 100).toFixed(2)}</td>
          </tr>
          <tr>
            <td colSpan="5" className="text-right">
              Total with Tax:
            </td>
            <td colSpan="2">${(total_amount_due / 100).toFixed(2)}</td>
          </tr>
        </tbody>
      </table>
    )
  }
}

export default LineItemsTable;
