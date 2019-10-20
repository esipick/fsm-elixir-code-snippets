import React, { Component } from 'react';
import shortid from 'shortid';

export class LineItemRecord {
  constructor() {
    this.id = shortid.generate();
    this.description = '';
    this.rate = 0;
    this.quantity = 1;
    this.amount = 0;
  }
};

class InvoiceLineItem extends Component {
  constructor(props) {
    super(props);

    this.state = {
      item: props.item
    }
  }

  setDesc = (e) => {
    const item = Object.assign({}, this.state.item, { description: e.target.value });

    this.setState({ item });
    this.props.onChange(item);
  }

  setRate = (e) => {
    const rate = (parseInt(e.target.value) || 0) * 100;
    const item = Object.assign({}, this.state.item, { rate });

    this.calculateAmount(item);
  }

  setQty = (e) => {
    const item = Object.assign({}, this.state.item, { quantity: parseInt(e.target.value) || 0 });

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

  render() {
    const { item: { id, description, rate, quantity, amount } } = this.state;
    const { number, canRemove } = this.props;

    return (
      <tr key={id}>
        <td>{number}.</td>
        <td>
          <input type="text" className="form-control"
            value={description || ''}
            onChange={this.setDesc}
            required={true} />
        </td>
        <td>
          <input type="number" className="form-control"
            value={rate / 100}
            onChange={this.setRate}
            required={true} />
        </td>
        <td>
          <input type="number" className="form-control"
            value={quantity}
            onChange={this.setQty}
            required={true} />
        </td>
        <td>${(amount / 100).toFixed(2)}</td>
        <td className="remove-line-item-wrapper">
          { canRemove && <a className="remove-line-item" href="" onClick={this.remove}>&times;</a> }
        </td>
      </tr>
    )
  }
}

export default InvoiceLineItem;
