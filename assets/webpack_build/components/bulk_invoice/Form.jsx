import classnames from 'classnames';
import http from 'j-fetch';
import React, { Component } from 'react';
import Select from 'react-select';
import { debounce } from 'lodash';

import './styles.css';

import { authHeaders, addSchoolIdParam } from '../utils';
import Error from '../common/Error';

import Invoice from './Invoice';

import { PAYMENT_OPTIONS, DEFAULT_PAYMENT_OPTION, BALANCE } from '../invoice_form/constants';

import LowBalanceAlert from '../invoice_form/LowBalanceAlert';
import ErrorAlert from '../invoice_form/ErrorAlert';

class BulkInvoiceForm extends Component {
  constructor(props) {
    super(props);

    this.formRef = null;

    this.state = {
      id: this.props.id || '',
      error: props.error || '',
      errors: props.errors || {},
      stripe_error: props.stripe_error || '',
      student: props.student,
      students: [],
      invoices: [],
      all_invoices_selected: false,
      selected_invoices: [],
      payment_method: DEFAULT_PAYMENT_OPTION,
      balance_warning_open: false,
      balance_warning_accepted: false,
      error_alert_open: false,
      total_amount_due: 0
    }
  };

  componentDidMount() {
    this.loadData();
  };

  loadData = () => {
    this.loadStudents();
  };

  loadStudents = () => {
    return http.get({ url: '/api/users/by_role?role=student', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { this.setState({ students: r.data }); })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  };

  loadInvoices = (student) => {
    if (!student) student = this.state.student;

    if (!student) { return };
    if (this.state.invoices_loading) return;

    this.setState({ invoices_loading: true });

    http.get({
      url: '/api/invoices?skip_pagination=true&status=0&user_id=' + student.id + addSchoolIdParam('&'),
      headers: authHeaders()
    }).then(r => r.json())
      .then(r => {
        this.setState({ invoices: r.data, invoices_loading: false });
      })
      .catch(err => {
        err.json().then(e => {
          console.warn(e);
          this.setState({ invoices_loading: false });
        })
      });
  };

  globalError = () => {
    if ('error' in this.state) return this.state.error.message
  };

  setFormRef = (form) => {
    this.formRef = form;

    form.addEventListener("submit", (event) => { event.preventDefault() });
  };

  setStudent = (student) => {
    const payload = { student, total_amount_due: 0, invoices: [] };

    this.setState(payload, () => { this.loadInvoices(); });
  }

  saveBulkInvoice = () => {
    if (this.state.saving) return;

    this.setState({ saving: true });

    const { student, invoices, total_amount_due, payment_method } = this.state;
    const invoice_ids = invoices.map(i => i.id);

    const bulk_invoice = {
      user_id: student.id,
      total_amount_due,
      payment_option: payment_method.value,
      invoice_ids
    }

    http.post({
      url: `/api/bulk_invoices`,
      body: { bulk_invoice },
      headers: authHeaders()
    }).then(response => {
      response.json().then(({ data }) => {
        window.location = `/billing/transactions/${data.transaction_id}`;
      });
    }).catch(response => {
      response.json().then((error_body) => {
        console.warn(error_body);
        const { id = this.state.id, stripe_error = '', error = '', errors = {} } = error_body;
        const action = id ? 'edit' : 'create';
        this.setState({
          saving: false, id, action,
          stripe_error, error, errors,
          error_alert_open: this.state.total <= 0
        });
      });
    });
  }

  submitForm = () => {
    if (this.state.saving) return;

    if (this.state.total_amount_due <= 0) {
      this.setState({error_alert_open: true});
      return;
    }

    if (this.showBalanceWarning()) return;

    if (this.formRef.checkValidity()) {
      this.saveBulkInvoice();
    }
  }

  toggleAllInvoicesSelected = () => {
    const all_invoices_selected = !this.state.all_invoices_selected;
    const invoices = this.state.invoices.map(i => {
      i.checked = all_invoices_selected;
      return i
    });
    const total_amount_due = this.calculateTotal();

    this.setState({ all_invoices_selected, invoices, total_amount_due });
  }

  onInvoiceSelect = (id) => {
    const invoices = this.state.invoices.map(i => {
      if (i.id == id) i.checked = !i.checked;

      return i;
    });
    const total_amount_due = this.calculateTotal();
    const all_invoices_selected = invoices.filter(i => i.checked).length > 0;

    this.setState({ invoices, total_amount_due, all_invoices_selected });
  }

  calculateTotal = () => {
    const { invoices } = this.state;
    const calculator = (sum, i) => sum + i.total_amount_due;

    return invoices.filter(i => i.checked).reduce(calculator, 0);
  }

  setPaymentMethod = (option) => { this.setState({ payment_method: option }); }

  showBalanceWarning = () => {
    const { total_amount_due, student, payment_method, balance_warning_accepted } = this.state;

    const open = !balance_warning_accepted &&
      payment_method.value == BALANCE &&
      student &&
      total_amount_due > student.balance;

    if (open) this.setState({ balance_warning_open: true });

    return open;
  }

  closeBalanceWarning = () => {
    this.setState({ balance_warning_open: false });
  }

  closeErrorAlert = () => {
    this.setState({ error_alert_open: false });
  }

  acceptBalanceWarning = () => {
    this.setState({ balance_warning_open: false, balance_warning_accepted: true });

    this.saveBulkInvoice();
  }

  accountBalance = () => {
    if (!this.state.student) return "0.00";

    return (this.state.student.balance * 1.0 / 100).toFixed(2);
  }

  invoicesTableHeaders = () => {
    return (
      <div className="row bulk-invoice__invoice">
        <div className="col-md-3 col-xs-3 bulk-invoice__invoice-item">
          <div className="checkbox">
            <input checked={this.state.all_invoices_selected}
              id="all-invoices-selected"
              onChange={this.toggleAllInvoicesSelected}
              type="checkbox" />
            <label htmlFor="all-invoices-selected" />
          </div>
        </div>
        <div className="col-md-3 col-xs-3 bulk-invoice__invoice-item">ID</div>
        <div className="col-md-3 col-xs-3 bulk-invoice__invoice-item">Date</div>
        <div className="col-md-3 col-xs-3 bulk-invoice__invoice-item">Amount Due</div>
      </div>
    )
  }

  render() {
    const {
      all_invoices_selected, student, students, invoices, invoices_loading,
      total_amount_due, selectedInvoices, errors, stripe_error, saving, payment_method
    } = this.state;

    const payBtnDisabled = saving || !student || invoices_loading;

    return (
      <div className="card">
        <div className="card-header text-left">
          <h3 className="card-title">Bulk Payment</h3>
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
                  <div className={classnames('invoice-select-wrapper', errors.user_id ? 'with-error' : '')}>
                    <Select id="student-name"
                      placeholder="Student name"
                      classNamePrefix="react-select"
                      options={students}
                      onChange={this.setStudent}
                      getOptionLabel={(o) => (o.label || o.first_name + ' ' + o.last_name)}
                      getOptionValue={(o) => o.id}
                      value={student} />
                  </div>
                </div>

                <div className="form-group">
                  <label>Acct Balance</label>
                  <div className="account-balance">${this.accountBalance()}</div>
                </div>

                <div className="form-group">
                  <label>
                    Invoices
                  </label>
                  { invoices.length ? this.invoicesTableHeaders() : null}
                  <div>
                    { invoices.map(invoice =>
                        <Invoice key={invoice.id} onSelect={this.onInvoiceSelect} {...invoice} />
                      )
                    }
                  </div>
                </div>

                <div className="form-group">
                  <label>
                    Total Amount
                  </label>
                  <div id="total-amount-due">
                    ${ (total_amount_due / 100.0).toFixed(2) }
                  </div>
                </div>

                <div className="form-group">
                  <label>
                    Payment method
                    <Error text={errors.payment_option} />
                  </label>
                  <div className="invoice-select-wrapper">
                    <Select id="payment-method"
                      placeholder="Payment method"
                      value={payment_method}
                      classNamePrefix="react-select"
                      options={PAYMENT_OPTIONS}
                      onChange={this.setPaymentMethod}
                      required={true} />
                  </div>
                  <div><Error text={stripe_error} /></div>
                </div>

                <div className="form-group invoice-save-buttons">
                  <input id="pay"
                    className="btn btn-primary"
                    type="submit"
                    value="Pay"
                    disabled={payBtnDisabled}
                    onClick={() => { this.submitForm() }} />
                </div>

                <div className="form-group">
                  <Error text={this.globalError() || stripe_error} />
                </div>
              </form>
            </div>
          </div>
        </div>

        <LowBalanceAlert open={this.state.balance_warning_open}
          onClose={this.closeBalanceWarning}
          onAccept={this.acceptBalanceWarning}
          balance={student ? student.balance : 0}
          total={total_amount_due} />

        <ErrorAlert open={this.state.error_alert_open}
            onAccept={this.closeErrorAlert}
            text="Total amount must be greater than zero." />
      </div>
    );
  }
}

export default BulkInvoiceForm;
