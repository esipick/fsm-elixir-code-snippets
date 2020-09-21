import NumberFormat from 'react-number-format';
import React, { Component } from 'react';
import Select from 'react-select';

import Error from '../../common/Error';

import {
  DESCRIPTION_SELECT_OPTS, DEFAULT_TYPE, TYPES, SIMULATOR_HOURS,
  NUMBER_INPUT_OPTS, DEFAULT_RATE, populateHobbsTach
} from './line_item_utils';

const MAX_INT = 2147483647;
const NUMBER_PROPS = {
  allowNegative: false,
  className: "form-control inherit-font-size",
  decimalScale: 1,
  fixedDecimalScale: 1,
  required: true,
  thousandSeparator: true
};

class AircraftLineItem extends Component {
  constructor(props) {
    super(props);

    const { creator, staff_member, line_item } = props;
    const { aircraft } = line_item;
    
    this.state = {
      aircraft,
      line_item,
    }

    this.setRate(this.props.line_item);
  }

  updateLineItem = (line_item) => {
    this.setState({ line_item });
    this.props.onChange(line_item);
  }

  setDesc = (option) => {
    const line_item = this.props.itemFromOption(this.state.line_item, option);

    this.updateLineItem(line_item);
  }

  calculateAmount = (line_item) => {
    line_item.amount = (line_item.rate * line_item.quantity);

    this.updateLineItem(line_item);
  }

  componentDidMount() {
    this.setRate(this.props.line_item);
  }

  setRate = (line_item) => {
    
    if ((line_item.demo || line_item.persist_rate) && line_item.rate > 0) {      
      this.calculateAmount(line_item)
      return
    }

    const { aircraft } = this.state;
    if (line_item.aircraft && (this.getAccountBalance() >=1 )) {
      // this.setState({ rate: this.props.line_item.aircraft.block_rate_per_hour });
      line_item.rate = this.props.line_item.aircraft.block_rate_per_hour;
    }
    else if(line_item.aircraft){
      line_item.rate = this.props.line_item.aircraft.rate_per_hour;
    }
    else {
      line_item;
    }
    line_item.quantity = 0;
    line_item.amount = 0;

    this.updateLineItem(line_item);
  }

  setCustomRate = ({ floatValue = 0}) => {
    const rate = floatValue >= MAX_INT ? MAX_INT : floatValue * 100;
    let line_item = Object.assign({}, this.state.line_item, { rate: rate});

    if (!line_item.demo && !line_item.enable_rate) {return}
    this.setRate(line_item)
  }

  getAccountBalance = () => {
    if (!this.props.student) return 0;

    return (this.props.student.balance * 1.0 / 100).toFixed(2);
  }

  remove = (e) => {
    e.preventDefault();

    this.props.onRemove(this.state.line_item.id);
  }

  setAircraft = (aircraft) => { 
    const rate = aircraft ? this.state.line_item.rate : DEFAULT_RATE;
    const aircraft_id = aircraft ? aircraft.id : null;
    const amount = rate * this.state.line_item.quantity;
    var payload = { rate, aircraft_id, amount };
    
    if (this.props.user_roles && (this.props.user_roles.includes("admin") || this.props.user_roles.includes("dispatcher"))) {
      payload = { rate, aircraft_id, amount, enable_rate: true, persist_rate: true }
    }

    const line_item = Object.assign(
      {}, this.state.line_item, payload, populateHobbsTach(aircraft)
    );

    this.setState({ aircraft, line_item });
    this.props.onChange(line_item);
  }

  aircraftSelect = (disable_selection) => {
    const { errors, editable } = this.props;
    const { aircrafts_loading } = this.state;
    var {aircraft} = this.state

    disable_selection = disable_selection || !editable

    var options = this.props.aircrafts

    if (this.props.line_item.description === SIMULATOR_HOURS) {
      options = this.props.simulators
      aircraft = aircraft && aircraft.simulator == false ? null : aircraft
    
    } else {
      aircraft = aircraft && !aircraft.simulator ? aircraft : null
    }

    return (
      <div>
        <Select classNamePrefix="react-select"
          getOptionLabel={(o) => o.tail_number || (o.make + ' ' + o.model)}
          getOptionValue={(o) => o.id}
          isClearable={true}
          isDisabled={disable_selection}
          onChange={this.setAircraft}
          options={options}
          placeholder="Tail #"
          value={aircraft} />
        <Error text={errors.aircraft_id} />
      </div>
    );
  }

  setHobbsStart = ({ floatValue = 0 }) => {
    const { line_item } = this.state;
    line_item.hobbs_start = floatValue >= MAX_INT ? this.state.hobbs_start : floatValue * 10;

    this.updateLineItem(line_item);
  }

  setHobbsEnd = ({ floatValue = 0 }) => {
    const { line_item } = this.state;
    line_item.hobbs_end = floatValue >= MAX_INT ? this.state.hobbs_end : floatValue * 10;

    this.updateLineItem(line_item);
  }

  setTachStart = ({ floatValue = 0 }) => {
    const { line_item } = this.state;
    line_item.tach_start = floatValue >= MAX_INT ? this.state.tach_start : floatValue * 10;

    this.updateLineItem(line_item);
  }

  setTachEnd = ({ floatValue = 0 }) => {
    const { line_item } = this.state;
    line_item.tach_end = floatValue >= MAX_INT ? this.state.tach_end : floatValue * 10;

    this.updateLineItem(line_item);
  }

  render() {
    const { aircraft, line_item } = this.state;
    const {
      hobbs_start, hobbs_end, tach_start, tach_end, id, description, disable_flight_hours, enable_rate,
    } = line_item;
    const { number, canRemove, errors, lineItemTypeOptions, editable } = this.props;
    const { rate, quantity, amount } = this.props.line_item;
    const descriptionOpt = lineItemTypeOptions.find(o => o.value == description);
    const wrapperClass = Object.keys(this.props.errors).length ? 'lc-row-with-error' : '';
    
    const hobbsTachNotDisabledInputProps = Object.assign({}, NUMBER_PROPS, { disabled: disable_flight_hours });
    const hobbsTachInputProps = Object.assign({}, NUMBER_PROPS, { disabled: !aircraft || !editable || disable_flight_hours });
    const hobbsErr = (this.props.line_item.errors || {}).aircraft_details || {};
    const hobbsWrapperClass = (hobbsErr.hobbs_start || hobbsErr.hobbs_end) ? 'lc-row-with-error' : '';
    const tachWrapperClass = (hobbsErr.tach_start || hobbsErr.tach_end) ? 'lc-row-with-error' : '';

    return (
      <React.Fragment>
        <tr key={id} className={wrapperClass}>
          <td>{number}.</td>
          <td className="lc-desc-column">
            <Select defaultValue={descriptionOpt.label ? descriptionOpt : null}
              onChange={this.setDesc}
              isDisabled={!editable}
              options={lineItemTypeOptions}
              {...DESCRIPTION_SELECT_OPTS} />
            <Error text={errors.description} />
          </td>
          <td className="lc-desc-column">
            {this.aircraftSelect(disable_flight_hours)}
          </td>
          <td className="lc-column"></td>
          <td className="lc-column"></td>
          <td className="lc-column"></td>
          <td className="lc-column remove-line-item-wrapper">
            {canRemove && editable &&
              <a className="remove-line-item" href="" onClick={this.remove}>&times;</a>}
          </td>
        </tr>
        <tr key={id + "_hobbs_time"} className={hobbsWrapperClass}>
          <td></td>
          <td>
            <label>Hobbs Start *</label>
            <NumberFormat {...hobbsTachInputProps}
              disabled={disable_flight_hours}
              onValueChange={this.setHobbsStart}
              value={hobbs_start / 10} />
            <Error text={hobbsErr.hobbs_start} className="hobbs-and-tach__error" />
          </td>
          <td>
            <label>Hobbs End *</label>
            <NumberFormat {...hobbsTachNotDisabledInputProps}
              onValueChange={this.setHobbsEnd}
              value={hobbs_end / 10} />
            <Error text={hobbsErr.hobbs_end} className="hobbs-and-tach__error" />
          </td>
          <td>
            <label>Rate</label>
            <NumberFormat disabled={!enable_rate} onValueChange={this.setCustomRate} value={rate == null ? null : rate / 100} {...NUMBER_INPUT_OPTS} />
            {errors.rate && <br />}
            <Error text={errors.rate} />
          </td>
          <td>
            <label>Duration</label>
            <NumberFormat disabled={true} value={quantity} {...NUMBER_INPUT_OPTS} />
            <Error text={errors.quantity} />
          </td>
          <td className="lc-column">
            <label style={{visibility: 'hidden'}}>Amount</label>
            <div style={{padding: '10px 18px'}}>${(amount / 100).toFixed(2)}</div>
          </td>
          <td></td>
        </tr>
        <tr key={id + "_tach_time"} className={tachWrapperClass}>
          <td></td>
          <td>
            <label>Tach Start *</label>
            <NumberFormat {...hobbsTachInputProps}
              onValueChange={this.setTachStart}
              value={tach_start / 10} />
            <Error text={hobbsErr.tach_start} className="hobbs-and-tach__error" />
          </td>
          <td>
            <label>Tach End *</label>
            <NumberFormat {...hobbsTachNotDisabledInputProps}
              onValueChange={this.setTachEnd}
              value={tach_end / 10} />
            <Error text={hobbsErr.tach_end} className="hobbs-and-tach__error" />
          </td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
        </tr>
      </React.Fragment>
    )
  }
}

export default AircraftLineItem;
