import classnames from 'classnames';
import http from 'j-fetch';
import React, { Component } from 'react';
import Select from 'react-select';
import { debounce } from 'lodash';

import { authHeaders, addSchoolIdParam } from '../utils';
import Error from '../common/Error';

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
      invoices: []
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
      url: '/api/invoices?status=0&user_id=' + student.id + addSchoolIdParam('&'),
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
    this.setState({ student }, () => { this.loadInvoices(); });
  }

  saveBulkInvoice = () => {
    if (this.state.saving) return;

    this.setState({ saving: true });

    setTimeout(() => {
      this.setState({ saving: false });
    }, 3000)
  }

  submitForm = () => {
    if (this.state.saving) return;

    if (this.formRef.checkValidity()) {
      this.saveBulkInvoice();
    }
  }

  render() {
    const { student, students, invoices, selectedInvoices, errors, stripe_error, saving } = this.state;

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
                    <Select placeholder="Student name"
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
                    Invoices
                  </label>
                  <div className={classnames('invoice-select-wrapper', errors.user_id ? 'with-error' : '')}>
                    <Select placeholder="Invoices"
                      isMulti
                      classNamePrefix="react-select"
                      options={invoices}
                      onChange={this.setStudent}
                      getOptionLabel={(o) => (o.id)}
                      getOptionValue={(o) => o.id}
                      isDisabled={!student}
                      value={selectedInvoices} />
                  </div>
                </div>

                <div className="form-group invoice-save-buttons">
                  <input className="btn btn-primary"
                    type="submit"
                    value="Pay"
                    disabled={saving}
                    onClick={() => { this.submitForm() }} />
                </div>

                <div className="form-group">
                  <Error text={this.globalError() || stripe_error} />
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

export default BulkInvoiceForm;
