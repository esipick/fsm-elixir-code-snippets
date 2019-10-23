import classnames from 'classnames';
import React, { Component } from 'react';
import Select from 'react-select';
import AsyncSelect from 'react-select/async';
import http from 'j-fetch';
import DatePicker from 'react-datepicker';

import Error from '../common/Error';

import LineItemsTable from './LineItemsTable';

const BALANCE = 'balance';
const CREDIT_CARD = 'cc';
const CASH = 'cash';
const CHECK = 'check';
const VENMO = 'venmo';

const MARK_AS_PAID = 'Save and Mark as paid';
const PAY = 'Save and Pay';

const DEFAULT_PAYMENT_OPTION = { value: BALANCE, label: 'Balance' };
const PAYMENT_OPTIONS = [
  DEFAULT_PAYMENT_OPTION,
  { value: CREDIT_CARD, label: 'Credit Card' },
  { value: CASH, label: 'Cash' },
  { value: CHECK, label: 'Check' },
  { value: VENMO, label: 'Venmo' }
];

const authHeaders = () => ({ 'Authorization': window.fsm_token });

class Form extends Component {
  constructor(props) {
    super(props);

    this.formRef = null;

    this.state = {
      id: this.props.id || '',
      date: props.date && new Date(props.date) || new Date,
      student: props.student,
      line_items: props.line_items || [],
      sales_tax: props.tax_rate || 0,
      payment_method: this.getPaymentMethod(props.payment_option),
      action: props.action || 'create',
      total: props.total || 0,
      total_tax: props.total_tax || 0,
      total_amount_due: props.total_amount_due || 0,
      errors: props.errors || {},
      stripe_error: props.stripe_error || ''
    }
  }

  getPaymentMethod = (payment_option) => {
    const finded_option = PAYMENT_OPTIONS.find((option) => {
      return option.value == payment_option
    });

    return finded_option || DEFAULT_PAYMENT_OPTION;
  }

  setFormRef = (form) => {
    this.formRef = form;

    form.addEventListener("submit", (event) => { event.preventDefault() });
  };

  loadStudents = (input, callback) => {
    this.setState({ students_loading: true });

    http.get({
        url: '/api/users/autocomplete?name=' + input,
        headers: authHeaders()
      }).then(r => r.json())
      .then(r => {
        callback(r.data);
        this.setState({ students_loading: false });
      })
      .catch(err => {
        err.json().then(e => {
          callback([]);
          this.setState({ students_loading: false });
        })
      });
  }

  accountBalance = () => {
    if (!this.state.student) return 0;

    return (this.state.student.balance * 1.0 / 100).toFixed(2);
  }

  setStudent = (student) => { this.setState({ student }); }

  setDate = (date) => { this.setState({ date }); }

  setPaymentMethod = (option) => { this.setState({ payment_method: option }); }

  onLineItemsTableChange = (values) => { this.setState(values); }

  payload = () => {
    const {
      student, sales_tax, total, total_tax, total_amount_due, date, payment_method, action
    } = this.state;

    const line_items = action == 'edit' ? this.state.line_items : this.state.line_items.map(i => {
      delete Object.assign({}, i).id;
      return i;
    });

    return {
      line_items,
      user_id: student && student.id,
      date: date.toISOString(),
      tax_rate: sales_tax,
      total: total,
      total_tax: total_tax,
      total_amount_due: total_amount_due,
      payment_option: payment_method.value
    }
  }

  saveInvoice = ({ pay_off }) => {
    if (this.state.saving) return;

    if (this.formRef.checkValidity()) {
      this.setState({ saving: true });

      const payload = this.payload();
      const http_method = this.state.action == 'edit' ? 'put' : 'post';

      http[http_method]({
        url: `/api/invoices/${this.state.id}`,
        body: { pay_off: pay_off, invoice: payload },
        headers: authHeaders()
      }).then(response => {
        response.json().then(({ data }) => {
          console.log(JSON.stringify(data));
          window.location = `/admin/billing/invoices/${data.id}`;
        })
      }).catch(response => {
        response.json().then(({ id = this.state.id, stripe_error = '', errors = {} }) => {
          const action = id ? 'edit' : 'create';
          this.setState({ saving: false, id, action, stripe_error, errors });
        });
      });
    }
  }

  globalError = () => {
    if (Object.keys(this.state.errors).length > 0) {
      return "Could not save invoice. Please correct errors in the form.";
    }
  }

  saveAndPayButton = () => {
    const { payment_method: { value }, saving } = this.state;
    const inputValue = [CASH, CHECK, VENMO].includes(value) ? MARK_AS_PAID : PAY

    return(
      <input className="btn btn-danger invoice-form__pay-btn"
        type="submit"
        disabled={saving}
        value={inputValue}
        onClick={()=>{this.saveInvoice({ pay_off: true })}} />
    );
  }

  header = () => {
    const { id } = this.state;
    const header = id ? `Edit Invoice #${id}` : 'New Invoice';

    return header;
  }

  render() {
    const {
      students_loading, student, date, line_items, sales_tax, total, total_tax,
      total_amount_due, payment_method, errors, stripe_error, saving, id
    } = this.state;
    const studentWrapperClass = classnames('invoice-select-wrapper', errors.user_id ? 'with-error' : '');

    return (
      <div className="card">
        <div className="card-header text-left">
          <h3 className="card-title">{this.header()}</h3>
        </div>

        <div className="card-body">
          <div className="invoice-form">
            <div className="form">
              <form ref={this.setFormRef}>
                <div className="form-group">
                  <label>
                    Student name
                    <Error text={errors.user_id} />
                  </label>
                  <div className={studentWrapperClass}>
                    <AsyncSelect placeholder="Student name"
                      classNamePrefix="react-select"
                      loadOptions={this.loadStudents}
                      onChange={this.setStudent}
                      isLoading={students_loading}
                      getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
                      getOptionValue ={(o) => o.id}
                      value={student} />
                  </div>
                </div>

                <div className="form-group">
                  <label>Acct Balance</label>
                  <div>${this.accountBalance()}</div>
                </div>

                { id && <div className="form-group">
                  <label>Invoice #</label>
                  <div>{id}</div>
                </div> }

                <div className="form-group">
                  <label>
                    Date
                    <Error text={errors.date} />
                  </label>
                  <div>
                    <DatePicker className="form-control invoice-input"
                      selected={date}
                      onChange={this.setDate} />
                  </div>
                </div>

                <div className="form-group">
                  <LineItemsTable line_items={line_items}
                    onChange={this.onLineItemsTableChange}
                    sales_tax={sales_tax}
                    total={total}
                    total_tax={total_tax}
                    total_amount_due={total_amount_due} />
                </div>

                <div className="form-group">
                  <label>
                    Payment method
                    <Error text={errors.payment_option} />
                  </label>
                  <div className="invoice-select-wrapper">
                    <Select placeholder="Payment method"
                      value={payment_method}
                      classNamePrefix="react-select"
                      options={PAYMENT_OPTIONS}
                      onChange={this.setPaymentMethod}
                      required={true} />
                  </div>
                  <div><Error text={stripe_error} /></div>
                </div>

                <div className="form-group">
                  <input className="btn btn-primary"
                    type="submit"
                    value="Save"
                    disabled={saving}
                    onClick={()=>{this.saveInvoice({ pay_off: false })}} />

                  { this.saveAndPayButton() }
                </div>

                <div className="form-group">
                  <Error text={this.globalError()} />
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

export default Form;
