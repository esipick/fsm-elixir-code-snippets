import React, { Component } from 'react';
import Select from 'react-select';
import AsyncSelect from 'react-select/async';
import http from 'j-fetch';
import DatePicker from 'react-datepicker';

import Error from '../common/error';

import LineItemsTable from './LineItemsTable';

const BALANCE = 'balance';
const CREDIT_CARD = 'credit_card';
const CASH = 'cash';
const CHECK = 'check';
const VENMO = 'venmo';

const PAYMENT_OPTIONS = [
  { value: BALANCE, label: 'Balance' },
  { value: CREDIT_CARD, label: 'Credit Card' },
  { value: CASH, label: 'Cash' },
  { value: CHECK, label: 'Check' },
  { value: VENMO, label: 'Venmo' }
];

class Form extends Component {
  constructor(props) {
    super(props);

    this.state = {
      date: props.date || new Date(),
      student: props.student,
      line_items: props.line_items || [],
      sales_tax: props.sales_tax || 0,
      payment_method: props.payment_method || BALANCE,
      action: props.action || 'create'
    }
  }

  loadStudents = (input, callback) => {
    const complete = false;
    this.setState({ students_loading: true });

    http.get({
        url: '/api/users/autocomplete?name=' + input,
        headers: { 'Authorization': window.fsm_token }
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

  setPaymentMethod = ({ value }) => { this.setState({ payment_method: value }); }

  setLineItems = (line_items) => { this.setState({ line_items }); }

  setSalesTax = (sales_tax) => { this.setState({ sales_tax }); }

  payload = () => {
    const { student, sales_tax, date, payment_method, action } = this.state;
    const line_items = action == 'edit' ? this.state.line_items : this.state.line_items.map(i => {
      delete i.id;
      return i;
    });

    return {
      student_id: student && student.id,
      account_balance: student && student.balance,
      date: date.toUTCString(),
      sales_tax,
      payment_method,
      line_items
    }
  }

  saveInvoice = () => {
    const payload = this.payload();

    console.log(payload);
  }

  render() {
    return (
      <div className="invoice-form">
        <div className="form">
          <div className="form-group">
            <label>
              Student name
              <Error text="" />
            </label>
            <div className="invoice-select-wrapper">
              <AsyncSelect placeholder="Student name"
                classNamePrefix="react-select"
                loadOptions={this.loadStudents}
                onChange={this.setStudent}
                isLoading={this.state.students_loading}
                getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
                getOptionValue ={(o) => o.id} />
            </div>
          </div>

          <div className="form-group">
            <label>Acct Balance</label>
            <div>${this.accountBalance()}</div>
          </div>

          <div className="form-group">
            <label>Date</label>
            <div>
              <DatePicker className="form-control invoice-input"
                selected={this.state.date} onChange={this.setDate} />
            </div>
          </div>

          <div className="form-group">
            <LineItemsTable items={this.state.line_items}
              onChange={this.setLineItems}
              sales_tax={this.state.sales_tax}
              onSalesTaxChange={this.setSalesTax} />
          </div>

          <div className="form-group">
            <label>Payment method</label>
            <div className="invoice-select-wrapper">
              <Select placeholder="Payment method"
                defaultValue={this.state.payment_method}
                classNamePrefix="react-select"
                options={PAYMENT_OPTIONS}
                onChange={this.setPaymentMethod} />
            </div>
          </div>

          <div className="form-group">
            <button className="btn btn-primary" onClick={this.saveInvoice}>Save</button>
          </div>
        </div>
      </div>
    );
  }
}

export default Form;
