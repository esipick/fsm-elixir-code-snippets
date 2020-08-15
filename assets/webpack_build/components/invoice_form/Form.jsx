import classnames from 'classnames';
import http from 'j-fetch';
import React, { Component } from 'react';
import DatePicker from 'react-datepicker';
import Select from 'react-select';
import CreatableSelect from 'react-select/creatable';
import { debounce } from 'lodash';

// import "core-js/stable";
import "regenerator-runtime/runtime";
import { loadStripe } from "@stripe/stripe-js";

import { authHeaders, addSchoolIdParam } from '../utils';
import Error from '../common/Error';

import { itemsFromInvoice } from './line_items/line_item_utils';

import LineItemsTable from './LineItemsTable';
import LowBalanceAlert from './LowBalanceAlert';
import ErrorAlert from './ErrorAlert';

import {
  BALANCE, CASH, CHECK, VENMO, MARK_AS_PAID, PAY,
  GUEST_PAYMENT_OPTIONS, DEFAULT_PAYMENT_OPTION, PAYMENT_OPTIONS, DEMO_PAYMENT_OPTIONS
} from './constants';

let calculateRequest = () => { };

class Form extends Component {
  
  constructor(props) {
    super(props);

    this.formRef = null;
    const { creator, staff_member, appointment } = props;
    const {stripe_account_id, pub_key} = props

    const appointments = appointment ? [appointment] : [];

    this.state = {
      appointment,
      appointments,
      id: props.id || '',
      sales_tax: props.tax_rate || 0,
      action: props.action || 'create',
      error: props.error || '',
      errors: props.errors || {},
      stripe_error: props.stripe_error || '',
      error_alert_total_open: false,
      error_alert_total_due_open: false,
      error_alert_total_tax_open: false,
      error_date_alert_open: false,
      balance_warning_open: false,
      balance_warning_accepted: false,
      payment_method: {},
      line_items: [],
      is_visible: true,
      student: staff_member ? undefined : creator,
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
        const invoice = itemsFromInvoice(r.data);

        var demo = false
        if(invoice.appointment){ demo = invoice.appointment.demo }

        this.setState({
          date: invoice.date ? new Date(invoice.date) : new Date(),
          student: invoice.user || this.guestPayer(demo, invoice.payer_name),
          line_items: invoice.line_items || [],
          payment_method: this.getPaymentMethod(demo ? DEFAULT_PAYMENT_OPTION : invoice.payment_option),
          demo: demo,
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
    if (!this.props.staff_member) return;

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
          appointments = [default_appointment, ...r.data].filter(e => e);
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

      const date = moment.utc(start_at).add(+(moment().utcOffset()), 'm').format('YYYY-MM-DD')
      const start_time = moment.utc(start_at).add(+(moment().utcOffset()), 'm').format('hh:mmA');
      const end_time = moment.utc(end_at).add(+(moment().utcOffset()), 'm').format('hh:mmA');
      const instructor =
        instructor_user ? `, Instructor: ${instructor_user.first_name} ${instructor_user.last_name}` : '';

      return `${date}, ${start_time} - ${end_time}${instructor}`;
    } else {
      return '';
    }
  }

  demoFlightAppointment = (appointment) => {
    const { demo } = appointment;
      return demo;
  }

  setAppointment = (appointment) => {
    this.setState({ appointment });
  }

  accountBalance = () => {
    if (this.state.student && this.state.appointment){
      return "";
    } else if (!this.state.student) {
      return "0.00";
    } else {
      return (this.state.student.balance * 1.0 / 100).toFixed(2);
    }
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

      this.setState({ student, appointment }, () => { this.loadAppointments(); });
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

  guestPayer = (demo, payer_name) => ({
    label: payer_name,
    balance: 0,
    id: null,
    guest: true,
    demo: typeof (demo) != "undefined" ? demo : false
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
      payment_method, action, is_visible
    } = this.state;
    const is_edit = action == 'edit';

    const line_items = is_edit ? this.state.line_items : this.state.line_items.map(i => {
      delete Object.assign({}, i).id;
      return i;
    });

    return {
      ignore_last_time: is_edit,
      line_items,
      user_id: student && student.id,
      payer_name: student && student.guest ? student.label : '',
      date: date.toISOString(),
      tax_rate: sales_tax,
      total,
      total_tax,
      total_amount_due,
      payment_option: payment_method.value,
      is_visible: is_visible,
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
        if (data.session_id) {
          this.stripeCheckout(data.session_id, data.connect_account, data.pub_key)
          return;
        }

        window.location = `/billing/invoices/${data.id}`;
      });
    }).catch(response => {
      response.json().then((error_body) => {
        console.warn(error_body);
        const { id = this.state.id, stripe_error = '', error = '', errors = {} } = error_body;
        const action = id ? 'edit' : 'create';
        this.setState({
          saving: false, id, action,
          stripe_error, error, errors,
          error_alert_total_open: this.state.total <= 0
        });
      });
    });
  }

  calculateTotal = (line_items, callback) => {
    if (calculateRequest.hasOwnProperty('cancel')) {
      calculateRequest.cancel();
    }

    const { student, appointment, action } = this.state;
    const payload = {
      ignore_last_time: action == 'edit',
      line_items,
      user_id: student && student.id,
      appointment_id: appointment && appointment.id
    }

    if (!this.state.saving) this.setState({ saving: true });

    calculateRequest = debounce(payloadParams => {
      http.post({
        url: '/api/invoices/calculate?' + addSchoolIdParam(),
        body: { invoice: payloadParams },
        headers: authHeaders()
      }).then(response => {
        this.setState({ saving: false });
        response.json().then(callback);
      }).catch(response => {
        this.setState({ saving: false });
        response.json().then((err) => {
          console.warn(err);
        });
      });
    }, 500);

    calculateRequest(payload);
  }

  async stripeCheckout(sessionId, accountId, pub_key) {
    const stripe = await loadStripe(pub_key, {stripeAccount: accountId});

    stripe.redirectToCheckout({
        sessionId:sessionId
      })
      .then(({ error }) => {
        console.log(error);
      });
  }

  submitForm = ({ pay_off }) => {
    console.log("saving")

    if (this.state.saving) return;
    if (this.state.total <= 0) {
      this.setState({error_alert_total_open: true});
      return;
    }
    if (this.state.total_amount_due <= 0) {
      this.setState({error_alert_total_due_open: true});
      return;
    }
    if (this.state.total_tax < 0) {
      this.setState({error_alert_total_tax_open: true});
      return;
    }

    if ( this.state.line_items.length > 0) {
      for (let increment in this.state.line_items) {
        if (this.state.line_items[increment].type == "aircraft") {
          if(typeof(this.state.line_items[increment].errors) != "undefined") {
            return;
          }
          else{
            if (pay_off && (typeof(this.state.appointment) == "undefined" || (this.state.appointment) && Date.now() < Date.parse(moment.utc(this.state.appointment.start_at).add(+(moment().utcOffset()), 'm').format().split("Z")[0]))) {
              this.setState({error_date_alert_open: true});
              return;
            }
          }
        }
      }
    }

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

  closeBalanceWarning = () => {
    this.setState({ balance_warning_open: false });
  }

  closeTotalErrorAlert = () => {
    this.setState({ error_alert_total_open: false });
  }

  closeTotalDueErrorAlert = () => {
    this.setState({ error_alert_open: false });
  }

  closeTotalTaxErrorAlert = () => {
    this.setState({ error_alert_total_due_open: false });
  }

  closeErrorDateAlert = () => {
    this.setState({ error_date_alert_open: false });
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

  studentSelect = () => {
    const { errors, student, students } = this.state;

    return (
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
    )
  }

  render() {
    const { custom_line_items, staff_member } = this.props;
    const { aircrafts, appointment, appointment_loading, appointments,
      instructors, date, errors, id, invoice_loading, line_items, payment_method, demo, sales_tax,
      saving, stripe_error, student, total, total_amount_due, total_tax
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
                  { staff_member && this.studentSelect() }
                  { !staff_member && <div>{student.first_name + ' ' + student.last_name}</div> }
                </div>

                <div className="form-group">
                  <label>
                    Appointment
                    <Error text={errors.appointment_id} />
                  </label>
                  <div className={classnames('invoice-select-wrapper', errors.appointment_id ? 'with-error' : '')}>
                    <Select placeholder="Appointment"
                      isClearable
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
                    Payment Date
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
                      staff_member={staff_member}
                      custom_line_items={custom_line_items}
                      errors={errors}
                      instructors={instructors}
                      line_items={line_items}
                      onChange={this.onLineItemsTableChange}
                      calculateTotal={this.calculateTotal}
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
                      options={student && student.guest && !demo ? GUEST_PAYMENT_OPTIONS : demo ? DEMO_PAYMENT_OPTIONS : PAYMENT_OPTIONS}
                      onChange={this.setPaymentMethod}
                      required={true} />
                  </div>
                  <div><Error text={stripe_error} /></div>
                </div>

                <div id="save_and_pay" className="form-group invoice-save-buttons">
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

        <LowBalanceAlert open={this.state.balance_warning_open}
          onClose={this.closeBalanceWarning}
          onAccept={this.acceptBalanceWarning}
          balance={student ? student.balance : 0}
          total={total_amount_due}
        />

      <ErrorAlert open={this.state.error_alert_total_open}
          onAccept={this.closeTotalErrorAlert}
          text="Invoices cannot be saved with a total amount below or equal to zero."
      />

      <ErrorAlert open={this.state.error_alert_total_due_open}
          onAccept={this.closeTotalDueErrorAlert}
          text="Invoices cannot be saved with a total amount below or equal to zero."
      />

      <ErrorAlert open={this.state.error_alert_total_tax_open}
          onAccept={this.closeTotalTaxErrorAlert}
          text="Invoices cannot be saved with a total amount below or equal to zero."
      />


      <ErrorAlert open={this.state.error_date_alert_open}
          onAccept={this.closeErrorDateAlert}
          text="Invoice associated with aircraft cannot be paid before the starting time of appointment."
      />
      </div>
    );
  }
}

export default Form;
