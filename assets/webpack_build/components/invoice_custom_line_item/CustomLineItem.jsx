import NumberFormat from 'react-number-format';
import React, { Component } from 'react';
import { authHeaders } from '../utils';
import Error from '../common/Error';

class CustomLineItem extends Component {
  constructor(props) {
    super(props);

    this.formRef = null;

    const { default_rate, description, taxable, deductible } = this.props.custom_line_item

    this.state = {
      default_rate: `${default_rate / 100}`,
      description,
      errors: {},
      saving: true,
      taxable,
      deductible
    }
  }

  setFormRef = (form) => {
    this.formRef = form;
  };

  payload = () => {
    const { taxable, description, default_rate, deductible } = this.state;
    const default_rate_to_cents = Math.round(default_rate.replace(/,/g, '') * 100)

    return {
      deductible,
      taxable,
      description,
      default_rate: default_rate_to_cents
    }
  }

  save = () => {
    if (this.state.saving) return;

    this.setState({ saving: true });
    const { custom_line_item: { id }, school_id } = this.props
    const payload = this.payload();
    
    fetch(`/api/invoices/${school_id}/custom_line_items/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({custom_line_item: payload}),
      headers: {
        ...authHeaders(),
        'Content-Type': 'application/json; charset=utf-8'
      }
    }).then(response => {
      response.json().then(({ description, default_rate }) => {
        this.setState({ saving: true, description, default_rate: default_rate / 100 });
      });
    }).catch(response => {
      response.json().then(({ errors = {} }) => {
        this.setState({ saving: false, errors });
      });
    });
  }

  submitForm = (e) => {
    e.preventDefault()

    if (this.state.saving) return
    if (this.formRef.checkValidity()) { this.save() }
  }

  delete = (e) => {
    e.preventDefault();

    const { custom_line_item: { id }, onRemove, school_id } = this.props

    fetch(`/api/invoices/${school_id}/custom_line_items/${id}`, {
      method: 'DELETE',
      headers: authHeaders()
    }).then(response => {
      if (response.status == 204) {
        onRemove(id);
      }
    })
  }

  onDescriptionChange = (e) => {
    this.setState({ description: e.target.value, saving: false })
  }

  onRateChange = (e) => {
    this.setState({ default_rate: e.target.value, saving: false })
  }

  onTaxableChange = () => {
    const { taxable } = this.state;

    this.setState({ taxable: !taxable, saving: false });
  }

  onDeductibleChange = () => {
    const { deductible } = this.state;

    this.setState({ deductible: !deductible, saving: false });
  }

  render() {
    const { default_rate, description, errors, saving, taxable, deductible } = this.state;
    const deductibleCss = '';

    return (
      <form className="row" ref={this.setFormRef}>
        <div className={`col-md-3 pr-1 ${deductibleCss}`}>
          <div className="form-group m-0">
            <input className="form-control"
              onChange={this.onDescriptionChange}
              placeholder="Description"
              type="text"
              value={description} />
          </div>
          <label>
            <Error text={errors.description} />
          </label>
        </div>
        <div className={`col-md-3 pr-1 ${deductibleCss}`}>
          <div className="form-group m-0">
            <NumberFormat allowNegative={false}
              className="form-control has-error"
              decimalScale={2}
              fixedDecimalScale={2}
              onChange={this.onRateChange}
              placeholder="Default rate"
              required={true}
              thousandSeparator={true}
              value={default_rate} />
          </div>
          <label>
            <Error text={errors.default_rate} />
          </label>
        </div>
        <div className={`col-md-2 pr-1 ${deductibleCss}`}>
          <div className="form-group m-0">
            <input type="checkbox"
              className="has-error"
              onChange={this.onTaxableChange}
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
        <div className={`col-md-2 pr-1 ${deductibleCss}`}>
          <div className="form-group m-0">
            <input type="checkbox"
              className="has-error"
              onChange={this.onDeductibleChange}
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
          <div className="row">
            <div className="col-md-8">
              <input className="btn btn-primary m-0"
                type="submit"
                value="Save"
                disabled={saving}
                onClick={this.submitForm} />
            </div>
            <div className="col-md-4">
              <a className="remove-line-item" href="" onClick={this.delete}>&times;</a>
            </div>
          </div>
        </div>
      </form>
    );
  }
}

export default CustomLineItem;
