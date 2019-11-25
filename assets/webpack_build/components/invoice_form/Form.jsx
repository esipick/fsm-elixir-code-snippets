import classnames from 'classnames';
import http from 'j-fetch';
import React, { Component } from 'react';
import DatePicker from 'react-datepicker';
import Select from 'react-select';
import AsyncCreatableSelect from 'react-select/async-creatable';

import { authHeaders } from '../utils';
import Error from '../common/Error';

import LineItemsTable from './LineItemsTable';
import LowBalanceAlert from './LowBalanceAlert';

const BALANCE = 'balance';
const CREDIT_CARD = 'cc';
const CASH = 'cash';
const CHECK = 'check';
const VENMO = 'venmo';

const MARK_AS_PAID = 'Save and Mark as paid';
const PAY = 'Save and Pay';

const GUEST_PAYMENT_OPTIONS = [
  { value: CASH, label: 'Cash' },
  { value: CHECK, label: 'Check' },
  { value: VENMO, label: 'Venmo' }
];
const DEFAULT_PAYMENT_OPTION = { value: BALANCE, label: 'Balance' };
const PAYMENT_OPTIONS = [
  DEFAULT_PAYMENT_OPTION,
  { value: CREDIT_CARD, label: 'Credit Card' },
  ...GUEST_PAYMENT_OPTIONS
];

class Form extends Component {
  constructor(props) {
    super(props);

    this.formRef = null;

    this.state = {
      id: this.props.id || '',
      sales_tax: props.tax_rate || 0,
      action: props.action || 'create',
      errors: props.errors || {},
      stripe_error: props.stripe_error || '',
      balance_warning_open: false,
      balance_warning_accepted: false,
      payment_method: {},
      line_items: []
    }
  }

  componentDidMount() {
    if (this.state.id) {
      this.loadInvoice().then(() => this.loadData());
    } else {
      this.loadData();
    }
  }

  loadData = () => {
    this.loadAppointments();
    this.loadAircrafts();
    this.loadInstructors();
  }

  loadAircrafts = () => {
    return http.get({ url: '/api/aircrafts', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { this.setState({ aircrafts: r.data }); })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  }

  loadInstructors = () => {
    return http.get({ url: '/api/users/by_role?role=instructor', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { this.setState({ instructors: r.data }); })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  }

  loadInvoice = () => {
    this.setState({ invoice_loading: true });

    return http.get({
        url: '/api/invoices/' + this.state.id,
        headers: authHeaders()
      }).then(r => r.json())
      .then(r => {
        const invoice = r.data;

        this.setState({
          date: invoice.date && new Date(invoice.date) || new Date(),
          student: invoice.user || this.guestPayer(invoice.payer_name),
          line_items: invoice.line_items || [],
          payment_method: this.getPaymentMethod(invoice.payment_option),
          sales_tax: invoice.tax_rate,
          total: invoice.total || 0,
          total_tax: invoice.total_tax || 0,
          total_amount_due: invoice.total_amount_due || 0,
          appointment: invoice.appointment,
          invoice_loading: false
        });
      })
      .catch(err => {
        if (err.json) {
          err.json().then(e => {
            console.warn(e);
            this.setState({ invoice_loading: false });
          });
        } else {
          console.warn(err);
          this.setState({ invoice_loading: false });
        }
      });
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
    if (this.state.students_loading) return;

    this.setState({ students_loading: true });

    http.get({
        url: '/api/users/autocomplete?role=student&name=' + input,
        headers: authHeaders()
      }).then(r => r.json())
      .then(r => {
        callback(r.data.map(s => Object.assign({}, s, { label: s.first_name + ' ' + s.last_name })));
        this.setState({ students_loading: false });
      })
      .catch(err => {
        err.json().then(e => {
          callback([]);
          this.setState({ students_loading: false });
        })
      });
  }

  loadAppointments = () => {
    const { student } = this.state;

    if (!student || student.guest) { return };
    if (this.state.appointment_loading) return;

    this.setState({ appointment_loading: true });

    http.get({
        url: '/api/invoices/appointments?user_id=' + student.id,
        headers: authHeaders()
      }).then(r => r.json())
      .then(r => {
        this.setState({ appointments: r.data, appointment_loading: false });
      })
      .catch(err => {
        err.json().then(e => {
          console.warn(e);
          this.setState({ appointment_loading: false });
        })
      });
  }

  appointmentLabel = (appointment) => {
    if (appointment) {
      const { start_at, end_at, aircraft, instructor_user } = appointment;

      const date = start_at.split("T")[0];
      const start_time = start_at.split("T")[1];
      const end_time = end_at.split("T")[1];
      const instructor =
        instructor_user ? `, Instructor: ${instructor_user.first_name} ${instructor_user.last_name}` : '';

      return `${date}, ${start_time} - ${end_time}${instructor}`;
    } else {
      return '';
    }
  }

  setAppointment = (appointment) => {
    this.setState({ appointment });
  }

  accountBalance = () => {
    if (!this.state.student) return 0;

    return (this.state.student.balance * 1.0 / 100).toFixed(2);
  }

  setStudent = (student) => {
    if (student) {
      this.setState({ student }, () => { this.loadAppointments(); });
    } else {
      this.setState({ student, appointments: [] });
    }
  }

  guestPayer = (payer_name) => ({
    label: payer_name,
    balance: 0,
    id: null,
    guest: true
  });

  createGuestPayer = (payer_name) => {
    const student = this.guestPayer(payer_name);

    this.setState({ student, appointments: [] });
  }

  isGuestNameValid = (inputValue, selectValue, selectOptions) => {
    return !(
      inputValue.trim().length === 0 ||
      selectOptions.find(option => option.name === inputValue)
    );
  };

  setDate = (date) => { this.setState({ date }); }

  setPaymentMethod = (option) => { this.setState({ payment_method: option }); }

  onLineItemsTableChange = (values) => { this.setState(values); }

  payload = () => {
    const {
      appointment, student, sales_tax, total, total_tax, total_amount_due, date,
      payment_method, action
    } = this.state;

    const line_items = action == 'edit' ? this.state.line_items : this.state.line_items.map(i => {
      delete Object.assign({}, i).id;
      return i;
    });

    return {
      line_items,
      user_id: student && student.id,
      payer_name: student && student.guest ? student.label : '',
      date: date.toISOString(),
      tax_rate: sales_tax,
      total: total,
      total_tax: total_tax,
      total_amount_due: total_amount_due,
      payment_option: payment_method.value,
      appointment_id: appointment && appointment.id
    }
  }

  showBalanceWarning = () => {
    const { total_amount_due, student, payment_method, balance_warning_accepted } = this.state;

    const open = !balance_warning_accepted &&
      payment_method.value == BALANCE &&
      student &&
      total_amount_due > student.balance;

    if (open) this.setState({ balance_warning_open: true });

    return open;
  }

  saveInvoice = ({ pay_off }) => {
    if (this.state.saving) return;

    this.setState({ saving: true });

    const payload = this.payload();
    const http_method = this.state.action == 'edit' ? 'put' : 'post';

    http[http_method]({
      url: `/api/invoices/${this.state.id}`,
      body: { pay_off: pay_off, invoice: payload },
      headers: authHeaders()
    }).then(response => {
      response.json().then(({ data }) => {
        window.location = `/billing/invoices/${data.id}`;
      });
    }).catch(response => {
      response.json().then(({ id = this.state.id, stripe_error = '', errors = {} }) => {
        const action = id ? 'edit' : 'create';
        this.setState({ saving: false, id, action, stripe_error, errors });
      });
    });
  }

  submitForm = ({ pay_off }) => {
    if (this.state.saving) return;

    if (pay_off && this.showBalanceWarning()) return;

    if (this.formRef.checkValidity()) {
      this.saveInvoice({ pay_off });
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
        onClick={()=>{this.submitForm({ pay_off: true })}} />
    );
  }

  header = () => {
    const { id } = this.state;
    const header = id ? `Edit Invoice #${id}` : 'New Invoice';

    return header;
  }

  openBalanceWarning = () => {
    this.setState({ balance_warning_open: true });
  }

  closeBalanceWarning = () => {
    this.setState({ balance_warning_open: false });
  }

  acceptBalanceWarning = () => {
    this.setState({ balance_warning_open: false, balance_warning_accepted: true });

    this.saveInvoice({ pay_off: true });
  }

  render() {
    const {
      appointment, appointment_loading, students_loading, student, date,
      line_items, sales_tax, total, total_tax, total_amount_due, payment_method,
      errors, stripe_error, saving, id
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
                    <AsyncCreatableSelect placeholder="Student name"
                      allowCreateWhileLoading={true}
                      isValidNewOption={this.isGuestNameValid}
                      onCreateOption={this.createGuestPayer}
                      classNamePrefix="react-select"
                      loadOptions={this.loadStudents}
                      onChange={this.setStudent}
                      isLoading={students_loading}
                      getOptionValue ={(o) => o.id}
                      value={student} />
                  </div>
                </div>

                <div className="form-group">
                  <label>
                    Appointment
                    <Error text={errors.appointment_id} />
                  </label>
                  <div className={studentWrapperClass}>
                    <Select placeholder="Appointment"
                      classNamePrefix="react-select"
                      options={this.state.appointments}
                      onChange={this.setAppointment}
                      isLoading={appointment_loading}
                      getOptionLabel={this.appointmentLabel}
                      getOptionValue ={(o) => o.id}
                      isDisabled={!student || student.guest}
                      value={appointment} />
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
                  { !this.state.invoice_loading &&
                    <LineItemsTable appointment={appointment}
                      line_items={line_items}
                      onChange={this.onLineItemsTableChange}
                      aircrafts={this.state.aircrafts}
                      instructors={this.state.instructors}
                      sales_tax={sales_tax}
                      total={total}
                      total_tax={total_tax}
                      total_amount_due={total_amount_due} /> }
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
                      options={student && student.guest ? GUEST_PAYMENT_OPTIONS : PAYMENT_OPTIONS}
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
                    onClick={()=>{this.submitForm({ pay_off: false })}} />

                  { this.saveAndPayButton() }
                </div>

                <div className="form-group">
                  <Error text={this.globalError()} />
                </div>
              </form>
            </div>
          </div>
        </div>

        <LowBalanceAlert open={this.state.balance_warning_open}
          onClose={this.closeBalanceWarning}
          onAccept={this.acceptBalanceWarning}
          balance={student ? student.balance : 0}
          total={total_amount_due}
        />
      </div>
    );
  }
}

export default Form;
