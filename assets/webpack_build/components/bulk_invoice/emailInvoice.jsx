import React, { PureComponent } from 'react';

const Invoice = (props) => {
  const { id, date, total_amount_due, checked, status } = props;

  return (
    <div className="row bulk-invoice__invoice">
      <div className="col-md-2 col-xs-3 bulk-invoice__invoice-item">
        <div className="checkbox">
          <input checked={checked || false}
            id="allCheckbox"
            onChange={() => props.onSelect(id)}
            type="checkbox" />
          <label htmlFor="allCheckbox" />
        </div>
      </div>
      <div className="col-md-2 col-xs- bulk-invoice__invoice-item">
        <a href={`/billing/invoices/${id}`} target="_blank">{id}</a>
      </div>
      <div className="col-md-2 col-xs-3 bulk-invoice__invoice-item">{status}</div>
      <div className="col-md-2 col-xs-3 bulk-invoice__invoice-item">{date}</div>
      <div className="col-md-2 col-xs-3 bulk-invoice__invoice-item">
        ${(total_amount_due / 100.0).toFixed(2)}
      </div>
    </div>
  )
}

export default Invoice;
