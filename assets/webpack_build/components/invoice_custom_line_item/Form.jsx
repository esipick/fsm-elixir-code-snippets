import classnames from 'classnames';
import http from 'j-fetch';
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';

import { authHeaders } from '../utils';
import Error from '../common/Error';
import CustomLineItemsTable from './CustomLineItemsTable';


class Form extends Component {
  constructor(props) {
    super(props);

    this.formRef = null;

    this.state = {
      custom_line_items: this.props.custom_line_items,
      default_rate: '',
      description: '',
      errors: {}
    }
  }

  setFormRef = (form) => {
    this.formRef = form;

    form.addEventListener("submit", (event) => { event.preventDefault() });
  };

  payload = () => {
    const { default_rate, description } = this.state;

    return {
      default_rate: default_rate.replace(/,/g, '') * 100,
      description: description
    }
  }

  removeCustomLineItem = (id) => {
    const custom_line_items = this.state.custom_line_items.filter(i => i.id != id);

    this.setState({ custom_line_items });
  }

  addCustomLineItem = (custom_line_item) => {
    const custom_line_items = this.state.custom_line_items;

    this.setState({
      custom_line_items: [...custom_line_items, custom_line_item],
      default_rate: '',
      description: '',
      errors: {},
      saving: false
    });
  }

  saveCustomLineItem = () => {
    if (this.state.saving) return;

    this.setState({ saving: true });
    const payload = this.payload();

    http['post']({
      url: `/api/invoices/${this.props.school_id}/custom_line_items`,
      body: { custom_line_item: payload },
      headers: authHeaders()
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
    const { default_rate, description, errors, custom_line_items, saving } = this.state;

    return (
      <div className="invoice-form">
        <h6>Add line item</h6>
        <p>Manage custom line items for the <a href="/billing/invoices/new">New Invoice</a> form.</p>
        <form ref={this.setFormRef}>
          <div className="row mb-4">
            <div className="col-md-5 pr-1">
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
            <div className="col-md-5 pr-1">
              <div className="form-group">
                <NumberFormat allowNegative={true}
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
      </div >
    );
  }
}

export default Form;
