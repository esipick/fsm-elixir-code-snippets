import classnames from 'classnames';
import React, { Component } from 'react';
import input from 'react-number-format';
import Select from 'react-select';
import Error from '../../common/Error';
import { getAccountBalance, isEmpty } from '../../utils';
import {
  DEFAULT_RATE, DESCRIPTION_SELECT_OPTS, INSTRUCTOR_HOURS, isInstructorHoursEditable, NUMBER_INPUT_OPTS, PARTS, ROOM
} from './line_item_utils';

class  OtherLineItem extends Component {
  constructor(props) {
    super(props);

    const { line_item, current_user_id } = props;
    const { instructor_user, room } = line_item;

    this.state = {
      room,
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

  isRoom = () => {
    return this.state.line_item.description === ROOM
  }

  roomSelect = () => {
    const { errors, editable } = this.props;
    const { instructors_loading, room } = this.state;

    return (
      <div>
        <Select classNamePrefix="react-select"
          getOptionLabel={(o) => o.location}
          getOptionValue={(o) => o.id}
          isClearable={true}
          isDisabled={!editable}
          onChange={this.setRoom} // change this to setRoom
          options={this.props.rooms} // change this to this.props.rooms.
          value={room}
          placeholder="Room" />
        <Error text={errors.room_id} />
      </div>
    );
  }

  getRoomRate = (room) => {
    let rate;
    if(room) {
       const balance = getAccountBalance(this.props.student);
       rate = balance === 0 ? room.rate_per_hour : room.block_rate_per_hour;
    }
    return rate ? rate : DEFAULT_RATE;
  }

  setRoom = (room) => {
    const rate = this.getRoomRate(room);
    const room_id = room ? room.id : null;
    const amount = rate * this.state.line_item.quantity;
    const payload = { rate, room_id, amount };
    const line_item = Object.assign({}, this.state.line_item, payload);

    this.setState({ room, line_item });
    this.props.onChange(line_item);
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
    const { number, canRemove, errors, lineItemTypeOptions, editable, staff_member, line_item: { amount }, user_roles } = this.props;
    const descriptionOpt = lineItemTypeOptions.find(o => o.value == description);
    const wrapperClass = Object.keys(this.props.errors).length ? 'lc-row-with-error' : '';
    const amountCss = classnames('lc-column', deductible ? 'deductible' : '');
    const rateClass = classnames(
      'form-control inherit-font-size', deductible ? 'deductible' : ''
    );
    const rateOpts = Object.assign({}, NUMBER_INPUT_OPTS, {className: rateClass});
    
    var shouldDisableRate = isInstructorHoursEditable(this.state.line_item, user_roles) || this.state.line_item.type === "room" 

    if (this.isRoom() && (user_roles.includes("admin") || user_roles.includes("dispatcher"))) {
      shouldDisableRate = false
    }
    
    if(!isEmpty(this.props.course)) {
      shouldDisableRate = true
    }

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
          {(this.isRoom() && this.roomSelect()) || (this.isInstructorHours() && this.instructorSelect())}
        </td>
        <td className="lc-column">
          <input onValueChange={this.setRate}
            value={rate == null ? null : rate / 100 }
            disabled={!staff_member || shouldDisableRate || !editable}
            {...rateOpts} />
          { errors.rate && <br /> }
          <Error text={errors.rate} />
        </td>
        <td className="lc-column">
          <input onValueChange={this.setQty}
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
