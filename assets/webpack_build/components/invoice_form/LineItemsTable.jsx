import React, { Component } from 'react';
import LineItem, { LineItemRecord } from './LineItem';
import NumericInput from 'react-numeric-input';

import { itemsFromAppointment } from './line_item_utils';

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

  addItem = () => {
    const line_items = [...this.lineItems(), new LineItemRecord()];
    this.updateTotal(line_items);
  }

  removeItem = (id) => {
    const line_items = this.lineItems().filter(i => i.id != id);
    this.updateTotal(line_items);
  }

  setItem = (item) => {
    const line_items = this.lineItems().map(i => i.id == item.id ? item : i);
    this.updateTotal(line_items);
  };

  calculateTotal = (line_items) => {
    const { sales_tax } = this.props;
    const total = line_items.reduce((sum, i) => (sum + i.rate * i.quantity), 0);
    const total_tax = Math.round((8551 * 33 / 100));
    const total_amount_due = total + total_tax;

    return {
      line_items,
      total,
      total_tax,
      total_amount_due
    }
  }

  updateTotal = (line_items) => {
    const values = this.calculateTotal(line_items);
    const { memo } = this.state;

    memo[lineItemsKey(this.state.appointment)] = values.line_items;

    this.setState({ ...values, memo });
    this.props.onChange(values);
  }

  render() {
    const { total, total_tax, total_amount_due } = this.state;
    const { sales_tax } = this.props;
    const line_items = this.lineItems();

    return (
      <table className="table table-striped">
        <thead>
          <tr>
            <th>#</th>
            <th>Description</th>
            <th></th>
            <th>Rate</th>
            <th>Qty/Hours</th>
            <th>Amount, $</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {
            line_items.map((item, i) => (
              <LineItem item={item}
                number={i + 1}
                key={item.id}
                onChange={this.setItem}
                canRemove={line_items.length > 1}
                onRemove={this.removeItem} />
            ))
          }
          <tr>
            <td colSpan="7">
              <button className="btn btn-sm btn-default" onClick={this.addItem}>Add</button>
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
              Sales Tax, %:
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
