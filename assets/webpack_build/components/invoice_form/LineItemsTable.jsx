import React, { Component } from 'react';
import LineItem, { LineItemRecord } from './LineItem';

class LineItemsTable extends Component {
  constructor(props) {
    super(props);

    const line_items = props.line_items.length > 0 ? props.line_items : [new LineItemRecord()];

    this.state = {
      line_items,
      sales_tax: props.sales_tax,
      total: props.total,
      total_tax: props.total_tax,
      total_amount_due: props.total_amount_due
    }
  }

  addItem = () => {
    const line_items = [...this.state.line_items, new LineItemRecord()];
    this.calculateTotal(this.state.sales_tax, line_items)
  }

  removeItem = (id) => {
    const line_items = this.state.line_items.filter(i => i.id != id);
    this.calculateTotal(this.state.sales_tax, line_items)
  }

  setItem = (item) => {
    const line_items = this.state.line_items.map(i => i.id == item.id ? item : i);
    this.calculateTotal(this.state.sales_tax, line_items)
  };

  setSalesTax = (e) => {
    const sales_tax = parseInt(e.target.value) || 0;
    this.calculateTotal(sales_tax, this.state.line_items)
  }

  calculateTotal = (sales_tax, line_items) => {
    const total = line_items.reduce((sum, i) => (sum + i.rate * i.quantity), 0);
    const total_tax = parseInt(total * sales_tax / 100);
    const total_amount_due = total + total_tax;

    const values = {
      line_items,
      total,
      sales_tax,
      total_tax,
      total_amount_due
    }

    this.setState(values);
    this.props.onChange(values);
  }

  render() {
    const { line_items, total, sales_tax, total_tax, total_amount_due } = this.state;

    return (
      <table className="table">
        <thead>
          <tr>
            <th>#</th>
            <th>Description</th>
            <th>Rate</th>
            <th>Qty</th>
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
            <td colSpan="6">
              <button className="btn btn-sm btn-default" onClick={this.addItem}>Add</button>
            </td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
              Total excl. taxes:
            </td>
            <td colSpan="2">${(total / 100).toFixed(2)}</td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
              Sales Tax, %:
            </td>
            <td colSpan="2">
              <input value={sales_tax}
                onChange={this.setSalesTax}
                className="form-control"
                type="number"
                required={true} />
            </td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
              Total tax:
            </td>
            <td colSpan="2">${(total_tax / 100).toFixed(2)}</td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
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
