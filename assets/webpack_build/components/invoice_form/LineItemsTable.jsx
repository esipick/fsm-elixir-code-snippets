import React, { Component } from 'react';
import LineItem, { LineItemRecord } from './LineItem';

class LineItemsTable extends Component {
  constructor(props) {
    super(props);

    const items = props.items.length > 0 ? props.items : [new LineItemRecord()];

    this.state = {
      items
    }
  }

  addItem = () => {
    this.setState({
      items: [...this.state.items, new LineItemRecord()]
    });
  }

  removeItem = (id) => {
    const items = this.state.items.filter(i => i.id != id);

    this.setState({ items });
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
                canRemove={items.length > 1}
                onRemove={this.removeItem} />
            ))
          }
          <tr>
            <td colSpan="6">
              <button className="btn btn-sm btn-default" onClick={this.addItem}>Add</button>
            </td>
          </tr>
        </tbody>
      </table>
    )
  }
}

export default LineItemsTable;
