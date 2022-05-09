import React, { PureComponent } from 'react';
import { isEmpty } from './../../utils';
import AircraftLineItem from './AircraftLineItem';
import { DEFAULT_RATE, DEFAULT_TYPE, DESCRIPTION_OPTIONS, MAINTENANCE_DESCRIPTION_OPTIONS, TYPES, MAINTENANCE_ONLY_OPTIONS } from './line_item_utils';
import OtherLineItem from './OtherLineItem';

class InvoiceLineItem extends PureComponent {

  lineItemTypeOptions = (maintenanceOptions, isMaintenanceInvoice) => {

    let options = DESCRIPTION_OPTIONS;
    
    if (isMaintenanceInvoice) {
      return MAINTENANCE_ONLY_OPTIONS
    }

    if(maintenanceOptions) {
      options = [...options, ...MAINTENANCE_DESCRIPTION_OPTIONS];
    }
        
    options = options.concat(this.props.custom_line_items.map(o => ({
      label: o.description,
      rate: o.default_rate,
      value: o.description,
      taxable: o.taxable,
      deductible: o.deductible,
      serial_number: o.serial_number,
      name: o.name,
      notes: o.notes
    })))
    
    const additionalOptions = this.props.line_items.filter(line_item => (
      !options.find(o => o.value == line_item.description) && line_item.description
    )).map(line_item => ({
      label: line_item.description,
      rate: line_item.rate,
      value: line_item.description,
      taxable: line_item.taxable,
      deductible: line_item.deductible,
      serial_number: line_item.serial_number,
      name: line_item.name,
      notes: line_item.notes
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
      serial_number: option.serial_number,
      name: option.name,
      notes: option.notes
    });
  }

  render() {
    const { line_item, creator, staff_member, is_admin_invoice, user_roles, is_maintenance_invoice } = this.props;
    let editable = staff_member || !line_item.creator_id || line_item.creator_id == creator.id;

    if(!isEmpty(this.props.course) || this.props.is_admin_invoice) {
      editable = false
    }

    const maintenanceOptions = staff_member && (hasRole(user_roles, "admin") ||
      hasRole(user_roles, "dispatcher") ||
      hasRole(user_roles, "mechanic"))

    const props = Object.assign({}, this.props, {
      lineItemTypeOptions: this.lineItemTypeOptions(maintenanceOptions, is_maintenance_invoice),
      itemFromOption: this.itemFromOption,
      editable,
    });
    
    if (line_item.type == 'aircraft') {
      return <AircraftLineItem {...props} />
    }
    
    return <OtherLineItem {...props} />
  }
}

const hasRole = (roles, role) => {
  return roles?.includes(role)
}

export default InvoiceLineItem;
