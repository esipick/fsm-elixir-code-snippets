import React, { Component } from 'react';
import Select from 'react-select';
import shortid from 'shortid';
import DatePicker from 'react-datepicker';
import InvoiceLineItem from './InvoiceLineItem';

import "react-datepicker/dist/react-datepicker.css";

const dummy_students = [
  { id: 1, first_name: 'John', last_name: 'Doe', balance: 5000 },
  { id: 2, first_name: 'Jane', last_name: 'Boa', balance: 3550 },
  { id: 3, first_name: 'Lee', last_name: 'Han U', balance: 4333 },
  { id: 4, first_name: 'James', last_name: 'Smith', balance: 1500 }
];

class LineItemRecord {
  constructor() {
    this.id = shortid.generate();
    this.rate = 0;
    this.qty = 1;
  }
};

class Hello extends Component {
  constructor(props) {
    super(props);

    this.state = {
      students: dummy_students,
      date: new Date(),
      lineItems: [
        new LineItemRecord()
      ]
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

  render() {
    console.log(this.state);

    return (
      <div className="invoice-form__wrapper">
        <div className="form">
          <div className="form-group">
            <Select placeholder="Student name"
              control={ { className: "form-control" } }
              options={this.state.students}
              onChange={this.setStudent}
              getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
              getOptionValue ={(o) => o.id} />
          </div>

          <div className="form-group">
            Acct Balance: ${this.accountBalance()}
          </div>

          <div className="form-group">
            <DatePicker className="form-control" selected={this.state.date} onChange={this.setDate} />
          </div>

          <div className="form-group">
            <table className="table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Description</th>
                  <th>Rate</th>
                  <th>Qty</th>
                  <th>Amount, $</th>
                </tr>
              </thead>
              <tbody>
                {
                  this.state.lineItems.map((item, i) => (
                    <InvoiceLineItem item={item} number={i + 1} key={item.id} />
                  ))
                }
              </tbody>
            </table>
          </div>
        </div>
      </div>
    );
  }
}

export default Hello;
