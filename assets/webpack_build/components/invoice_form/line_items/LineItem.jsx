import classnames from 'classnames';
import React, { PureComponent } from 'react';

import OtherLineItem from './OtherLineItem';
import AircraftLineItem from './AircraftLineItem';

import {
  DESCRIPTION_OPTS
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
      !options.find(o => o.value == line_item.description)
    )).map(line_item => ({
      label: line_item.description,
      rate: line_item.rate,
      value: line_item.description,
      taxable: line_item.taxable,
      deductible: line_item.deductible
    }));

    return [...options, ...additionalOptions];
  }

  render() {
    const { line_item } = this.props;

    const props = Object.assign({}, this.props, {
      lineItemTypeOptions: this.lineItemTypeOptions()
    });

    if (line_item.type == 'aircraft') {
      return <AircraftLineItem {...props} />
    } else {
      return <OtherLineItem {...props} />
    }
  }
}

export default InvoiceLineItem;
