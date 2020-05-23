import NumberFormat from 'react-number-format';
import React, { Component } from 'react';
import Select from 'react-select';

import Error from '../../common/Error';

import {
  DESCRIPTION_SELECT_OPTS, DEFAULT_TYPE, TYPES,
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

    const { line_item } = props;
    const { aircraft } = line_item;

    this.state = {
      aircraft,
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

  calculateAmount = (line_item) => {
    line_item.amount = (line_item.rate * line_item.quantity);

    this.updateLineItem(line_item);
  }

  remove = (e) => {
    e.preventDefault();

    this.props.onRemove(this.state.line_item.id);
  }

  setAircraft = (aircraft) => {
    const rate = aircraft ? aircraft.rate_per_hour : DEFAULT_RATE;
    const aircraft_id = aircraft ? aircraft.id : null;
    const amount = rate * this.state.line_item.quantity;
    const payload = { rate, aircraft_id, amount };
    const line_item = Object.assign(
      {}, this.state.line_item, payload, populateHobbsTach(aircraft)
    );

    this.setState({ aircraft, line_item });
    this.props.onChange(line_item);
  }

  aircraftSelect = () => {
    const { errors } = this.props;
    const { aircrafts_loading, aircraft } = this.state;

    return (
      <div>
        <Select classNamePrefix="react-select"
          getOptionLabel={(o) => o.tail_number}
          getOptionValue={(o) => o.id}
          isClearable={true}
          onChange={this.setAircraft}
          options={this.props.aircrafts}
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
      hobbs_start, hobbs_end, tach_start, tach_end, id, description
    } = line_item;
    const { number, canRemove, errors, lineItemTypeOptions } = this.props;
    const { rate, quantity, amount } = this.props.line_item;
    const descriptionOpt = lineItemTypeOptions.find(o => o.value == description);
    const wrapperClass = Object.keys(this.props.errors).length ? 'lc-row-with-error' : '';
    const hobbsTachInputProps = Object.assign({}, NUMBER_PROPS, { disabled: !aircraft });
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
              options={lineItemTypeOptions}
              {...DESCRIPTION_SELECT_OPTS} />
            <Error text={errors.description} />
          </td>
          <td className="lc-desc-column">
            {this.aircraftSelect()}
          </td>
          <td className="lc-column"></td>
          <td className="lc-column"></td>
          <td className="lc-column"></td>
          <td className="lc-column remove-line-item-wrapper">
            {canRemove && <a className="remove-line-item" href="" onClick={this.remove}>&times;</a>}
          </td>
        </tr>
        <tr key={id + "_hobbs_time"} className={hobbsWrapperClass}>
          <td></td>
          <td>
            <label>Hobbs Start *</label>
            <NumberFormat {...hobbsTachInputProps}
              onValueChange={this.setHobbsStart}
              value={hobbs_start / 10} />
            <Error text={hobbsErr.hobbs_start} className="hobbs-and-tach__error" />
          </td>
          <td>
            <label>Hobbs End *</label>
            <NumberFormat {...hobbsTachInputProps}
              onValueChange={this.setHobbsEnd}
              value={hobbs_end / 10} />
            <Error text={hobbsErr.hobbs_end} className="hobbs-and-tach__error" />
          </td>
          <td>
            <label>Rate</label>
            <NumberFormat disabled={true} value={rate == null ? null : rate / 100} {...NUMBER_INPUT_OPTS} />
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
            <NumberFormat {...hobbsTachInputProps}
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
