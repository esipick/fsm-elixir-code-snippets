import classnames from 'classnames';
import React, { PureComponent } from 'react';

import OtherLineItem from './OtherLineItem';
import AircraftLineItem from './AircraftLineItem';

import {
  DESCRIPTION_OPTS, DEFAULT_TYPE, TYPES, DEFAULT_RATE
} from './line_item_utils';

class InvoiceLineItem extends PureComponent {
  lineItemTypeOptions = () => {
    const options = DESCRIPTION_OPTS.concat(this.props.custom_line_items.map(o => ({
      label: o.description,
      rate: o.default_rate,
      value: o.description,
      taxable: o.taxable,
      deductible: o.deductible
    })))

    const additionalOptions = this.props.line_items.filter(line_item => (
      !options.find(o => o.value == line_item.description) && line_item.description
    )).map(line_item => ({
      label: line_item.description,
      rate: line_item.rate,
      value: line_item.description,
      taxable: line_item.taxable,
      deductible: line_item.deductible
    }));

    return [...options, ...additionalOptions];
  }

  itemFromOption = (line_item, option) => {
    const { quantity } = line_item;
    const type = TYPES[option.value] || DEFAULT_TYPE;
    const rate = option.rate || DEFAULT_RATE;

    return Object.assign({}, line_item, {
      description: option.value,
      rate,
      type,
      taxable: option.taxable,
      deductible: option.deductible,
      quantity: type == "aircraft" ? 0 : (quantity || 1),
      amount: rate * quantity
    });
  }

  render() {
    const { line_item } = this.props;

    const props = Object.assign({}, this.props, {
      lineItemTypeOptions: this.lineItemTypeOptions(),
      itemFromOption: this.itemFromOption
    });

    if (line_item.type == 'aircraft') {
      return <AircraftLineItem {...props} />
    } else {
      return <OtherLineItem {...props} />
    }
  }
}

export default InvoiceLineItem;
