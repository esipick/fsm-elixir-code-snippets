
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';
import { authHeaders } from '../utils';
import Error from '../common/Error';
import CustomLineItemsTable from './CustomLineItemsTable';

const DEFAULT_VALUES = {
  default_rate: '',
  description: '',
  taxable: false,
  deductible: false,
  saving: false,
  errors: {}
}

class Form extends Component {
  constructor(props) {
    super(props);

    this.formRef = null;

    this.state = Object.assign({
      custom_line_items: this.props.custom_line_items,
    }, DEFAULT_VALUES);
  }

  setFormRef = (form) => {
    this.formRef = form;
    form.addEventListener("submit", (event) => { event.preventDefault() });
  };

  payload = () => {
    const { default_rate, description, taxable, deductible } = this.state;
    const default_rate_to_cents = Math.round(default_rate.replace(/,/g, '') * 100)

    return {
      default_rate: default_rate_to_cents,
      description,
      taxable,
      deductible
    }
  }

  removeCustomLineItem = (id) => {
    const custom_line_items = this.state.custom_line_items.filter(i => i.id != id);
    this.setState({ custom_line_items });
  }

  addCustomLineItem = (custom_line_item) => {
    const custom_line_items = this.state.custom_line_items;
    const nextState = Object.assign({
      custom_line_items: [...custom_line_items, custom_line_item],
    }, DEFAULT_VALUES);

    this.setState(nextState);
  }

  saveCustomLineItem = () => {
    if (this.state.saving) return;

    this.setState({ saving: true });
    const payload = this.payload();

    fetch('', {
      method: 'POST',
      body: JSON.stringify({custom_line_item: payload}),
      headers: {
        ...authHeaders(),
        'Content-Type': 'application/json; charset=utf-8'
      }
    }).then(response => {
      response.json().then((custom_line_item) => {
        this.addCustomLineItem(custom_line_item)
      });
    }).catch(response => {
      response.json().then(({ errors = {} }) => {
        this.setState({ saving: false, errors });
      });
    });
  }

  submitForm = () => {
    if (this.state.saving) return;

    if (this.formRef.checkValidity()) {
      this.saveCustomLineItem();
    }
  }

  render() {
    const { default_rate, description, errors, custom_line_items, saving, taxable, deductible } = this.state;

    return (
      <div className="invoice-form">
        <h6>Add line item</h6>
        <p>Manage custom line items for the <a href="/billing/invoices/new">New Invoice</a> form.</p>
        <form ref={this.setFormRef}>
          <div className="row mb-4">
            <div className="col-md-3 pr-1">
              <div className="form-group">
                <input className="form-control"
                  onChange={e => this.setState({ description: e.target.value })}
                  placeholder="Description"
                  required={true}
                  type="text"
                  value={description} />
              </div>
              <label>
                <Error text={errors.description} />
              </label>
            </div>
            <div className="col-md-3 pr-1">
              <div className="form-group">
                <NumberFormat allowNegative={false}
                  className="form-control"
                  decimalScale={2}
                  fixedDecimalScale={2}
                  onChange={e => this.setState({ default_rate: e.target.value })}
                  placeholder="Default rate"
                  required={true}
                  thousandSeparator={true}
                  value={default_rate} />
              </div>
              <label>
                <Error text={errors.default_rate} />
              </label>
            </div>
            <div className="col-md-2 pr-1">
              <div className="form-group m-0">
                <input type="checkbox"
                  className="has-error"
                  onChange={() => this.setState({ taxable: !taxable })}
                  checked={taxable} />
              </div>
              <label>
                Taxable
                <span data-toggle="tooltip" data-placement="top" title="Select this if you want the application to calculate tax on the invoice. Products are typically taxable and services are not.">
              &nbsp;<b><svg width="1em" height="1em" viewBox="0 0 16 16" class="bi bi-question-circle" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"></path>
                <path d="M5.25 6.033h1.32c0-.781.458-1.384 1.36-1.384.685 0 1.313.343 1.313 1.168 0 .635-.374.927-.965 1.371-.673.489-1.206 1.06-1.168 1.987l.007.463h1.307v-.355c0-.718.273-.927 1.01-1.486.609-.463 1.244-.977 1.244-2.056 0-1.511-1.276-2.241-2.673-2.241-1.326 0-2.786.647-2.754 2.533zm1.562 5.516c0 .533.425.927 1.01.927.609 0 1.028-.394 1.028-.927 0-.552-.42-.94-1.029-.94-.584 0-1.009.388-1.009.94z"></path>
            </svg></b>
            </span>
                <Error text={errors.taxable} />
              </label>
            </div>
            <div className="col-md-2 pr-1">
              <div className="form-group m-0">
                <input type="checkbox"
                  className="has-error"
                  onChange={() => this.setState({ deductible: !deductible })}
                  checked={deductible} />
              </div>
              <label>
                Deductible
                <span data-toggle="tooltip" data-placement="top" title="Select this box if you want to deduct this item from the total as a negative charge. An example would be fuel purchased by the student that requires a reimbursement.">
              &nbsp;<b><svg width="1em" height="1em" viewBox="0 0 16 16" class="bi bi-question-circle" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"></path>
                <path d="M5.25 6.033h1.32c0-.781.458-1.384 1.36-1.384.685 0 1.313.343 1.313 1.168 0 .635-.374.927-.965 1.371-.673.489-1.206 1.06-1.168 1.987l.007.463h1.307v-.355c0-.718.273-.927 1.01-1.486.609-.463 1.244-.977 1.244-2.056 0-1.511-1.276-2.241-2.673-2.241-1.326 0-2.786.647-2.754 2.533zm1.562 5.516c0 .533.425.927 1.01.927.609 0 1.028-.394 1.028-.927 0-.552-.42-.94-1.029-.94-.584 0-1.009.388-1.009.94z"></path>
            </svg></b>
            </span>
                <Error text={errors.deductible} />
              </label>
            </div>
            <div className="col-md-2">
              <div className="form-group">
                <input className="btn btn-primary m-0"
                  type="submit"
                  value="Add"
                  disabled={saving}
                  onClick={() => { this.submitForm() }} />
              </div>
            </div>
          </div>
        </form>
        <CustomLineItemsTable custom_line_items={custom_line_items}
          onRemove={this.removeCustomLineItem}
          school_id={this.props.school_id}>
        </CustomLineItemsTable>
      </div>
    );
  }
}

export default Form;
