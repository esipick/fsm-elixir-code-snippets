import React, { Component } from 'react';
import LineItem, { LineItemRecord } from './LineItem';

class LineItemsTable extends Component {
  constructor(props) {
    super(props);

    const items = props.items.length > 0 ? props.items : [new LineItemRecord()];

    this.state = {
      items,
      sales_tax: props.sales_tax
    }
  }

  addItem = () => {
    const items = [...this.state.items, new LineItemRecord()];
    this.setState({ items });
    this.props.onChange(items);
  }

  removeItem = (id) => {
    const items = this.state.items.filter(i => i.id != id);

    this.setState({ items });
    this.props.onChange(items);
  }

  setItem = (item) => {
    const items = this.state.items.map(i => i.id == item.id ? item : i);

    this.setState({ items });
    this.props.onChange(items);
  };

  total = () => {
    return this.state.items.reduce((sum, i) => (sum + i.rate * i.qty), 0);
  }

  totalWithTax = () => {
    const total = this.total();

    return (total + total * this.state.sales_tax);
  }

  setSalesTax = (e) => {
    const sales_tax = (parseInt(e.target.value) || 0) / 100;
    this.setState({ sales_tax });
    this.props.onSalesTaxChange(sales_tax);
  }

  render() {
    const { items } = this.state;

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
            items.map((item, i) => (
              <LineItem item={item}
                number={i + 1}
                key={item.id}
                onChange={this.setItem}
                canRemove={items.length > 1}
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
              Total:
            </td>
            <td colSpan="2">${this.total().toFixed(2)}</td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
              Sales Tax, %:
            </td>
            <td colSpan="2">
              <input value={this.state.sales_tax * 100} onChange={this.setSalesTax} className="form-control" type="number" />
            </td>
          </tr>
          <tr>
            <td colSpan="4" className="text-right">
              Total with Tax:
            </td>
            <td colSpan="2">${this.totalWithTax().toFixed(2)}</td>
          </tr>
        </tbody>
      </table>
    )
  }
}

export default LineItemsTable;
