import React, { Component } from 'react';
import NumericInput from 'react-numeric-input';
import Select from 'react-select';
import shortid from 'shortid';

export class LineItemRecord {
  constructor() {
    this.id = shortid.generate();
    this.description = DESCRIPTION_OPTS[0].value;
    this.rate = 100;
    this.quantity = 1;
    this.amount = this.rate * this.quantity;
  }
};

const DESCRIPTION_OPTS = [
  "Flight Hours",
  "Instructor Hours",
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
