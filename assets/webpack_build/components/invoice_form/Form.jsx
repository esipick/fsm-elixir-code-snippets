import React, { Component } from 'react';
import AsyncSelect from 'react-select/async';
import http from 'j-fetch';
import DatePicker from 'react-datepicker';

import LineItemsTable from './LineItemsTable';

class Form extends Component {
  constructor(props) {
    super(props);

    this.state = {
      date: new Date(),
      lineItems: props.line_items || []
    }
  }

  accountBalance = () => {
    const { student } = this.state;

    if (student) {
      return (student.balance * 1.0 / 100).toFixed(2);
    } else return 0;
  }

  setStudent = (student) => {
    this.setState({ student });
  }

  setDate = (date) => {
    this.setState({ date });
  }

  fetchStudents = (query, onSuccess, onError) => {
    http.get({
        url: '/api/users/autocomplete?name=' + query,
        headers: { 'Authorization': window.fsm_token }
      }).then(r => r.json())
      .then(onSuccess)
      .catch(onError);
  }

  loadStudents = (input, callback) => {
    const complete = false;
    this.setState({ studentsLoading: true });

    this.fetchStudents(
      input,
      (r) => {
        console.log(r.data);
        callback(r.data);
        this.setState({ studentsLoading: false });
      },
      (response) => {
        response.json().then((e) => {
          callback(null, {
            options: [],
            complete
          });
          this.setState({ studentsLoading: false });
        });
      }
    );
  }

  render() {
    console.log(this.state);

    return (
      <div className="invoice-form__wrapper">
        <div className="form">
          <div className="form-group">
            <label>Student name</label>
            <AsyncSelect placeholder="Student name"
              classNamePrefix="react-select"
              loadOptions={this.loadStudents}
              onChange={this.setStudent}
              isLoading={this.state.studentsLoading}
              getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
              getOptionValue ={(o) => o.id} />
          </div>

          <div className="form-group">
            <label>Acct Balance</label>
            <div>${this.accountBalance()}</div>
          </div>

          <div className="form-group">
            <label>Date</label>
            <div>
              <DatePicker className="form-control" selected={this.state.date} onChange={this.setDate} />
            </div>
          </div>

          <div className="form-group">
            <LineItemsTable items={this.state.lineItems} />
          </div>
        </div>
      </div>
    );
  }
}

export default Form;
