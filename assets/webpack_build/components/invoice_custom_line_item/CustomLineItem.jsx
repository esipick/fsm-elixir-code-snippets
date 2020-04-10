import classnames from 'classnames';
import http from 'j-fetch';
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';

import { authHeaders } from '../utils';
import Error from '../common/Error';


class CustomLineItem extends Component {
  constructor(props) {
    super(props);

    this.formRef = null;

    const { default_rate, description, taxable } = this.props.custom_line_item

    this.state = {
      default_rate: `${default_rate / 100}`,
      description,
      errors: {},
      saving: true,
      taxable
    }
  }

  setFormRef = (form) => {
    this.formRef = form;
  };

  payload = () => {
    const { taxable, description, default_rate } = this.state;

    return {
      taxable: taxable == "on",
      description,
      default_rate: default_rate.replace(/,/g, '') * 100
    }
  }

  save = () => {
    if (this.state.saving) return;

    this.setState({ saving: true });
    const { custom_line_item: { id }, school_id } = this.props
    const payload = this.payload();

    http['patch']({
      url: `/api/invoices/${school_id}/custom_line_items/${id}`,
      body: { custom_line_item: payload },
      headers: authHeaders()
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

  submitForm = () => {
    event.preventDefault()

    if (this.state.saving) return
    if (this.formRef.checkValidity()) { this.save() }
  }

  delete = (e) => {
    e.preventDefault();

    const { custom_line_item: { id }, school_id } = this.props
    http['delete']({
      url: `/api/invoices/${school_id}/custom_line_items/${id}`,
      headers: authHeaders()
    }).then(response => {
      if (response.status == 204) {
        this.props.onRemove(id);
      }
    })
  }

  onDescriptionChange = (e) => {
    this.setState({ description: e.target.value, saving: false })
  }

  onRateChange = (e) => {
    this.setState({ default_rate: e.target.value, saving: false })
  }

  onTaxableChange = (e) => {
    this.setState({ taxable: e.target.value, saving: false });
  }

  render() {
    const { default_rate, description, errors, saving, taxable } = this.state;

    return (
      <form className="row" ref={this.setFormRef}>
        <div className="col-md-4 pr-1">
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
        <div className="col-md-3 pr-1">
          <div className="form-group m-0">
            <NumberFormat allowNegative={true}
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
        <div className="col-md-2 pr-1">
          <div className="form-group m-0">
            <input type="checkbox"
              className="form-control has-error"
              onChange={this.onTaxableChange}
              checked={taxable} />
          </div>
          <label>
            Taxable
            <Error text={errors.taxable} />
          </label>
        </div>
        <div className="col-md-3">
          <div className="row">
            <div className="col-md-8">
              <input className="btn btn-primary m-0"
                type="submit"
                value="Save"
                disabled={saving}
                onClick={() => { this.submitForm() }} />
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
