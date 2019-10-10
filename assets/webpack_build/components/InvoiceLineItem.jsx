import React, { Component } from 'react';

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
  }

  setRate = (e) => {
    const item = Object.assign({}, this.state.item, { rate: parseInt(e.target.value) });

    this.setState({ item });
  }

  setQty = (e) => {
    const item = Object.assign({}, this.state.item, { qty: parseInt(e.target.value) });

    this.setState({ item });
  }

  amount = () => {
    const { item } = this.state;

    return (item.rate * item.qty).toFixed(2);
  }

  render() {
    const { item } = this.state;

    return (
      <tr key={item.id}>
        <td>{this.props.number}.</td>
        <td>
          <input type="text" className="form-control"
            value={item.description || ''}
            onChange={this.setDesc} />
        </td>
        <td>
          <input type="number" className="form-control"
            value={item.rate}
            onChange={this.setRate} />
        </td>
        <td>
          <input type="number" className="form-control"
            value={item.qty}
            onChange={this.setQty} />
        </td>
        <td>${this.amount()}</td>
      </tr>
    )
  }
}

export default InvoiceLineItem;
