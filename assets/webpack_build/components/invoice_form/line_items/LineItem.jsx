import React, { PureComponent } from 'react';
import { isEmpty } from './../../utils';
import AircraftLineItem from './AircraftLineItem';
import { DEFAULT_RATE, DEFAULT_TYPE, DESCRIPTION_OPTS, TYPES } from './line_item_utils';
import MaintenaceLineItem from './maintenance-line-item';
import OtherLineItem from './OtherLineItem';

class InvoiceLineItem extends PureComponent {

  lineItemTypeOptions = () => {
    const options = DESCRIPTION_OPTS.concat(this.props.custom_line_items.map(o => ({
      label: o.description,
      rate: o.default_rate,
      value: o.description,
      taxable: o.taxable,
      deductible: o.deductible,
      part_number: o.part_number,
      part_cost: o.part_cost,
      part_name: o.part_name,
      part_description: o.part_description
    })))

    const additionalOptions = this.props.line_items.filter(line_item => (
      !options.find(o => o.value == line_item.description) && line_item.description
    )).map(line_item => ({
      label: line_item.description,
      rate: line_item.rate,
      value: line_item.description,
      taxable: line_item.taxable,
      deductible: line_item.deductible,
      part_cost: line_item.part_cost,
      part_number: line_item.part_number,
      part_name: o.part_name,
      part_description: o.part_description
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
      quantity: type === "aircraft" || type === "instructor" ? 0 : (quantity || 1),
      amount: rate * quantity,
      part_number: option.part_number,
      part_cost: option.part_cost,
      part_name: option.part_name,
      part_description: option.part_description
    });
  }

  render() {
    const { line_item, creator, staff_member, is_admin_invoice } = this.props;
    let editable = staff_member || !line_item.creator_id || line_item.creator_id == creator.id;

    if(!isEmpty(this.props.course) || this.props.is_admin_invoice) {
      editable = false
    }

    const props = Object.assign({}, this.props, {
      lineItemTypeOptions: this.lineItemTypeOptions(),
      itemFromOption: this.itemFromOption,
      editable,
    });

    if (line_item.type == 'aircraft') {
      return <AircraftLineItem {...props} />
    }
    
    if(line_item.type === "maintenance") {
      return <MaintenaceLineItem {...props} />
    }
    
    return <OtherLineItem {...props} />
  }
}

export default InvoiceLineItem;
