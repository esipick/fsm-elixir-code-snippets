import classnames from 'classnames';
import NumberFormat from 'react-number-format';
import React, { Component } from 'react';
import Select from 'react-select';

import Error from '../../common/Error';

import {
  DESCRIPTION_SELECT_OPTS, NUMBER_INPUT_OPTS, INSTRUCTOR_HOURS,
  DEFAULT_TYPE, TYPES, DEFAULT_RATE
} from './line_item_utils';
import { authHeaders } from '../../utils';

class OtherLineItem extends Component {
  constructor(props) {
    super(props);

    const { line_item } = props;
    const { instructor_user } = line_item;

    this.state = {
      instructor_user,
      line_item
    }
  }

  updateLineItem = (line_item) => {
    this.setState({ line_item });
    this.props.onChange(line_item);
  }

  setDesc = (option) => {
    const line_item = this.props.itemFromOption(this.state.line_item, option);

    this.updateLineItem(line_item);
  }

  setRate = ({ floatValue }) => {
    const rate = floatValue == null ? 0 : floatValue;
    let line_item = Object.assign({}, this.state.line_item, { rate: rate * 100});

    this.calculateAmount(line_item);

    if (floatValue == null) {
      line_item.rate = null;
      this.setState({ line_item })
    }
  }

  setQty = ({ floatValue }) => {
    const quantity = floatValue == null ? 0 : floatValue;
    let line_item = Object.assign({}, this.state.line_item, { quantity });

    this.calculateAmount(line_item);

    if (floatValue == null) {
      line_item.quantity = null;
      this.setState({ line_item })
    }
  }

  calculateAmount = (line_item) => {
    line_item.amount = (line_item.rate * line_item.quantity);

    this.updateLineItem(line_item);
  }

  remove = (e) => {
    e.preventDefault();

    this.props.onRemove(this.state.line_item.id);
  }

  isInstructorHours = () => {
    return this.state.line_item.description == INSTRUCTOR_HOURS;
  }

  setInstructor = (instructor_user) => {
    const rate = instructor_user ? instructor_user.billing_rate : DEFAULT_RATE;
    const instructor_user_id = instructor_user ? instructor_user.id : null;
    const amount = rate * this.state.line_item.quantity;
    const payload = { rate, instructor_user_id, amount };
    const line_item = Object.assign({}, this.state.line_item, payload);

    this.setState({ instructor_user, line_item });
    this.props.onChange(line_item);
  }

  instructorSelect = () => {
    const { errors, editable } = this.props;
    const { instructors_loading, instructor_user } = this.state;

    return (
      <div>
        <Select classNamePrefix="react-select"
          getOptionLabel={(o) => o.first_name + ' ' + o.last_name}
          getOptionValue={(o) => o.id}
          isClearable={true}
          isDisabled={!editable}
          onChange={this.setInstructor}
          options={this.props.instructors}
          value={instructor_user}
          placeholder="Instructor name" />
        <Error text={errors.instructor_user_id} />
      </div>
    );
  }

  render() {
    const {
      line_item: {
        id, description, rate, quantity, deductible
      }
    } = this.state;
    const { number, canRemove, errors, lineItemTypeOptions, editable, line_item: { amount } } = this.props;
    const descriptionOpt = lineItemTypeOptions.find(o => o.value == description);
    const wrapperClass = Object.keys(this.props.errors).length ? 'lc-row-with-error' : '';
    const amountCss = classnames('lc-column', deductible ? 'deductible' : '');
    const rateClass = classnames(
      'form-control inherit-font-size', deductible ? 'deductible' : ''
    );
    const rateOpts = Object.assign({}, NUMBER_INPUT_OPTS, {className: rateClass});

    return (
      <tr key={id} className={wrapperClass}>
        <td>{number}.</td>
        <td className="lc-desc-column">
          <Select defaultValue={descriptionOpt ? descriptionOpt : null}
            onChange={this.setDesc}
            options={lineItemTypeOptions}
            isDisabled={!editable}
            {...DESCRIPTION_SELECT_OPTS} />
          <Error text={errors.description} />
        </td>
        <td className="lc-desc-column">
          {this.isInstructorHours() && this.instructorSelect()}
        </td>
        <td className="lc-column">
          <NumberFormat onValueChange={this.setRate}
            value={rate == null ? null : rate / 100 }
            disabled={!editable}
            {...rateOpts} />
          { errors.rate && <br /> }
          <Error text={errors.rate} />
        </td>
        <td className="lc-column">
          <NumberFormat onValueChange={this.setQty}
            value={quantity}
            disabled={!editable}
            {...NUMBER_INPUT_OPTS} />
          <Error text={errors.quantity} />
        </td>
        <td className={amountCss}>${(amount / 100).toFixed(2)}</td>
        <td className="lc-column remove-line-item-wrapper">
          {canRemove && editable &&
            <a className="remove-line-item" href="" onClick={this.remove}>&times;</a>}
        </td>
      </tr>
    )
  }
}

export default OtherLineItem;
