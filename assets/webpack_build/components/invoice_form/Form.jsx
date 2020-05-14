import classnames from 'classnames';
import http from 'j-fetch';
import React, { Component } from 'react';
import DatePicker from 'react-datepicker';
import Select from 'react-select';
import CreatableSelect from 'react-select/creatable';

import { authHeaders, addSchoolIdParam } from '../utils';
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
      error: props.error || '',
      errors: props.errors || {},
      stripe_error: props.stripe_error || '',
      balance_warning_open: false,
      balance_warning_accepted: false,
      payment_method: {},
      line_items: [],
      date: new Date()
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
    this.loadStudents();
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
          date: invoice.date ? new Date(invoice.date) : new Date(),
          student: invoice.user || this.guestPayer(invoice.payer_name),
          line_items: invoice.line_items || [],
          payment_method: this.getPaymentMethod(invoice.payment_option),
          sales_tax: invoice.tax_rate,
          total: invoice.total || 0,
          total_tax: invoice.total_tax || 0,
          total_amount_due: invoice.total_amount_due || 0,
          appointment: invoice.appointment,
          default_appointment: invoice.appointment,
          default_user: invoice.user,
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

  loadStudents = () => {
    return http.get({ url: '/api/users/by_role?role=student', headers: authHeaders() })
      .then(r => r.json())
      .then(r => { this.setState({ students: r.data }); })
      .catch(err => {
        err.json().then(e => { console.warn(e); });
      });
  }

  loadAppointments = (student) => {
    if (!student) student = this.state.student;

    if (!student || student.guest) { return };
    if (this.state.appointment_loading) return;

    this.setState({ appointment_loading: true });

    http.get({
      url: '/api/invoices/appointments?user_id=' + student.id + addSchoolIdParam('&'),
      headers: authHeaders()
    }).then(r => r.json())
      .then(r => {
        let appointments;
        const { student, default_user, default_appointment } = this.state;

        if ((student && student.id) == (default_user && default_user.id)) {
          appointments = [default_appointment, ...r.data];
        } else {
          appointments = r.data;
        }

        this.setState({ appointments, appointment_loading: false });
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
    if (!this.state.student) return "0.00";

    return (this.state.student.balance * 1.0 / 100).toFixed(2);
  }

  setStudent = (student) => {
    if (student) {
      let appointment;
      const { default_user, default_appointment } = this.state;

      if ((student && student.id) == (default_user && default_user.id)) {
        appointment = default_appointment;
      } else {
        appointment = null;
      }

      this.setState({ student, appointment, }, () => { this.loadAppointments(); });
    } else {
      this.setState({ student, appointment: null, appointments: [] });
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

    this.setState({ student, appointments: [], payment_method: {} });
  }

  isGuestNameValid = (inputValue, selectValue, selectOptions) => {
    return !(
      inputValue.trim().length === 0 ||
      selectOptions.find(option => option.first_name + " " + option.last_name === inputValue)
    );
  };

  setDate = (date) => { console.log(date); this.setState({ date }); }

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
      response.json().then((error_body) => {
        console.warn(error_body);
        const { id = this.state.id, stripe_error = '', error = '', errors = {} } = error_body;
        const action = id ? 'edit' : 'create';
        this.setState({ saving: false, id, action, stripe_error, error, errors });
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
    if ('error' in this.state) return this.state.error.message
  }

  saveAndPayButton = () => {
    const { payment_method: { value }, saving } = this.state;
    const inputValue = [CASH, CHECK, VENMO].includes(value) ? MARK_AS_PAID : PAY

    return (
      <input className="btn btn-danger invoice-form__pay-btn"
        type="submit"
        disabled={saving}
        value={inputValue}
        onClick={() => { this.submitForm({ pay_off: true }) }} />
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

  userErrors = (errorText) => {
    if (errorText == "One of these fields must be present: [:user_id, :payer_name]") {
      return "can't be blank";
    } else {
      return errorText;
    }
  }

  render() {
    const { custom_line_items } = this.props
    const { aircrafts, appointment, appointment_loading, appointments, balance_warning_open,
      instructors, date, errors, id, invoice_loading, line_items, payment_method, sales_tax,
      saving, stripe_error, student, students, total, total_amount_due, total_tax
    } = this.state;

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
                    <Error text={this.userErrors(errors.user_id)} />
                  </label>
                  <div className={classnames('invoice-select-wrapper', errors.user_id ? 'with-error' : '')}>
                    <CreatableSelect placeholder="Student name"
                      isClearable
                      isValidNewOption={this.isGuestNameValid}
                      onCreateOption={this.createGuestPayer}
                      classNamePrefix="react-select"
                      options={students}
                      onChange={this.setStudent}
                      getOptionLabel={(o) => (o.label || o.first_name + ' ' + o.last_name)}
                      getOptionValue={(o) => o.id}
                      value={student} />
                  </div>
                </div>

                <div className="form-group">
                  <label>
                    Appointment
                    <Error text={errors.appointment_id} />
                  </label>
                  <div className={classnames('invoice-select-wrapper', errors.appointment_id ? 'with-error' : '')}>
                    <Select placeholder="Appointment"
                      classNamePrefix="react-select"
                      options={appointments}
                      onChange={this.setAppointment}
                      isLoading={appointment_loading}
                      getOptionLabel={this.appointmentLabel}
                      getOptionValue={(o) => o.id}
                      isDisabled={!student || student.guest}
                      value={appointment} />
                  </div>
                </div>

                <div className="form-group">
                  <label>Acct Balance</label>
                  <div>${this.accountBalance()}</div>
                </div>

                {id && <div className="form-group">
                  <label>Invoice #</label>
                  <div>{id}</div>
                </div>}

                <div className="form-group">
                  <label>
                    Date
                    <Error text={errors.date} />
                  </label>
                  <div>
                    <DatePicker className="form-control invoice-input"
                      selected={date}
                      required={true}
                      onChange={this.setDate} />
                  </div>
                </div>

                <div className="form-group">
                  {!invoice_loading &&
                    <LineItemsTable aircrafts={aircrafts}
                      appointment={appointment}
                      student={student}
                      creator={this.props.creator}
                      custom_line_items={custom_line_items}
                      errors={errors}
                      instructors={instructors}
                      line_items={line_items}
                      onChange={this.onLineItemsTableChange}
                      sales_tax={sales_tax}
                      total={total}
                      total_amount_due={total_amount_due}
                      total_tax={total_tax} />}
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

                <div className="form-group invoice-save-buttons">
                  <input className="btn btn-primary"
                    type="submit"
                    value="Save"
                    disabled={saving}
                    onClick={() => { this.submitForm({ pay_off: false }) }} />

                  {this.saveAndPayButton()}
                </div>

                <div className="form-group">
                  <Error text={this.globalError()} />
                </div>
              </form>
            </div>
          </div>
        </div>

        <LowBalanceAlert open={balance_warning_open}
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
