import React, { Component } from 'react';
import LineItem, { LineItemRecord } from './LineItem';
import NumericInput from 'react-numeric-input';

class LineItemsTable extends Component {
  constructor(props) {
    super(props);

    const line_items = props.line_items.length > 0 ? props.line_items : [new LineItemRecord()];
    const values = this.calculateTotal(props.sales_tax, line_items);

    this.state = {
      line_items,
      ...values
    }
  }

  addItem = () => {
    const line_items = [...this.state.line_items, new LineItemRecord()];
    this.updateTotal(this.props.sales_tax, line_items)
  }

  removeItem = (id) => {
    const line_items = this.state.line_items.filter(i => i.id != id);
    this.updateTotal(this.props.sales_tax, line_items)
  }

  setItem = (item) => {
    const line_items = this.state.line_items.map(i => i.id == item.id ? item : i);
    this.updateTotal(this.props.sales_tax, line_items)
  };

  setSalesTax = (value) => {
    const sales_tax = value / 100;
    this.updateTotal(sales_tax, this.state.line_items)
  }

  calculateTotal = (sales_tax, line_items) => {
    const total = line_items.reduce((sum, i) => (sum + i.rate * i.quantity), 0);
    const total_tax = parseInt(total * sales_tax);
    const total_amount_due = total + total_tax;

    return {
      line_items,
      total,
      total_tax,
      total_amount_due
    }
  }

  updateTotal = (sales_tax, line_items) => {
    const values = this.calculateTotal(sales_tax, line_items);

    this.setState(values);
    this.props.onChange(values);
  }

  render() {
    const { line_items, total, total_tax, total_amount_due } = this.state;
    const { sales_tax } = this.props;

    return (
      <table className="table table-striped">
        <thead>
          <tr>
            <th>#</th>
            <th>Description</th>
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
            <td colSpan="2">{sales_tax * 100}</td>
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
