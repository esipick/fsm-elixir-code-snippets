import React, { Component } from 'react';

import Error from '../common/Error';
import LineItem from './line_items/LineItem';

import { itemsFromAppointment, LineItemRecord } from './line_items/line_item_utils';

import { authHeaders, addSchoolIdParam } from '../utils';

const lineItemsKey = (appointment) => appointment && appointment.id || 'none';

class LineItemsTable extends Component {
  constructor(props) {
    super(props);

    const { appointment } = props;
    const line_items =
      props.line_items.length > 0 ? props.line_items : itemsFromAppointment(appointment);

    this.state = { line_items, appointment };
  }

  componentDidMount = () => {
    this.updateTotal(this.lineItems());
  }

    static getDerivedStateFromProps(props, state) {
      const prevAppointmentId = state.appointment && state.appointment.id;
      const appointmentId = props.appointment && props.appointment.id;

      if (prevAppointmentId !== appointmentId) {
        const { appointment } = props;
        const line_items = itemsFromAppointment(appointment);

        return { ...state, line_items, appointment };
      }

      return null;
    }

  lineItems = () => {
    return this.state.line_items;
  }

  addLineItem = () => {
    const line_items = [...this.lineItems(), new LineItemRecord()];

    this.setState({ line_items });
    this.props.onChange({ line_items });
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

  updateTotal = (line_items) => {
    this.setState({ line_items });
    this.props.calculateTotal(line_items, (values) => {
      console.log(values);
      this.setState({ ...values });
      this.props.onChange(values);
    });
  }

  render() {
    const { total, total_tax, total_amount_due } = this.state;
    const { aircrafts, custom_line_items, errors, instructors, sales_tax } = this.props;
    const line_items = this.lineItems();
    const line_items_errors = errors.line_items || [];

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
                errors={line_items_errors[i] || {}}
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
            <td colSpan="4" className="text-right">
              <Error text={errors.total} />
            </td>
            <td className="text-right">
              Total excl. taxes:
            </td>
            <td colSpan="2" className={total < 0 ? 'deductible' : ''}>
              ${(total / 100).toFixed(2)}
            </td>
          </tr>
          <tr>
            <td colSpan="5" className="text-right">
              Sales Tax %:
            </td>
            <td colSpan="2">{sales_tax}</td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
              <Error text={errors.total_tax} />
            </td>
            <td className="text-right">
              Total tax:
            </td>
            <td colSpan="2" className={total_tax < 0 ? 'deductible' : ''}>
              ${(total_tax / 100).toFixed(2)}
            </td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
              <Error text={errors.total_amount_due} />
            </td>
            <td className="text-right">
              Total with Tax:
            </td>
            <td colSpan="2" className={total_amount_due < 0 ? 'deductible' : ''}>
              ${(total_amount_due / 100).toFixed(2)}
            </td>
          </tr>
        </tbody>
      </table>
    )
  }
}

export default LineItemsTable;
