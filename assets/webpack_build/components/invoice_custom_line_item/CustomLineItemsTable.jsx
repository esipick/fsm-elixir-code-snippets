import React, { Component } from 'react';
import CustomLineItem from './CustomLineItem';

class CustomLineItemsTable extends Component {
  constructor(props) {
    super(props);
  }

  removeCustomLineItem = (id) => {
    this.props.onRemove(id)
  }

  render() {
    const { custom_line_items, school_id } = this.props

    return (
      <div className="items">
        <h6>Custom invoice line items</h6>
        <br></br>
        {custom_line_items.map((custom_line_item) => (
          <CustomLineItem custom_line_item={custom_line_item}
            key={custom_line_item.id}
            onRemove={this.removeCustomLineItem}
            school_id={school_id}>
          </CustomLineItem>
        ))}
      </div>
    );
  }
}

export default CustomLineItemsTable;
