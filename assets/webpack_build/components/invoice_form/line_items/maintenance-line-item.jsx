import classnames from "classnames";
import React, { Component } from "react";
import input from "react-number-format";
import Select from "react-select";
import Error from "../../common/Error";
import {
  DESCRIPTION_SELECT_OPTS,
  NUMBER_INPUT_OPTS,
  MAINTENANCE,
} from "./line_item_utils";

class MaintenaceLineItem extends Component {
  constructor(props) {
    super(props);

    const { line_item } = props;

    this.state = {
      line_item,
    };
  }

  updateLineItem = (line_item) => {
    this.setState({ line_item });
    this.props.onChange(line_item);
  };


  setDesc = (option) => {
    const line_item = this.props.itemFromOption(this.state.line_item, option);

    this.updateLineItem(line_item);
  }


  calculateAmount = (line_item) => {
    line_item.amount = line_item.rate * line_item.quantity;

    this.updateLineItem(line_item);
  };

  remove = (e) => {
    e.preventDefault();

    this.props.onRemove(this.state.line_item.id);
  };

  setPartCost = (cost) => {
    const part_cost = cost == null || isNaN(cost) ? 0 : cost * 100;
    let line_item = Object.assign({}, this.state.line_item, { part_cost });

    this.calculateAmount(line_item);
    this.setState({ line_item });
  };

  setPartDetail = (key, value) => {
    const part_value = value == null ? "" : value;
    let line_item = Object.assign({}, this.state.line_item, {
      [key]: part_value,
    });

    this.calculateAmount(line_item);
    this.setState({ line_item });
  };

  render() {
    const {
      line_item: {
        id,
        description,
        part_name,
        part_description,
        part_number,
        part_cost,
      },
    } = this.state;

    const {
      number,
      canRemove,
      errors,
      lineItemTypeOptions,
      editable
    } = this.props;
    const descriptionOpt = lineItemTypeOptions.find(
      (o) => o.value == description
    );
    const wrapperClass = Object.keys(this.props.errors).length
      ? "lc-row-with-error"
      : "";

    return (
      <>
        <tr key={id + "select"} className={wrapperClass}>
          <td>{number}.</td>
          <td className="lc-desc-column maintenance">
            <Select
              defaultValue={descriptionOpt ? descriptionOpt : null}
              onChange={this.setDesc}
              options={lineItemTypeOptions}
              isDisabled={!editable}
              {...DESCRIPTION_SELECT_OPTS}
            />
            <Error text={errors.description} />
          </td>
        </tr>
        <tr key={id + "data1"} className={wrapperClass}>
          <td className="lc-column maintenance">
            <label>Part Name</label>
            <input
              type={"text"}
              onChange={(event) =>
                this.setPartDetail("part_name", event.target.value)
              }
              value={part_name ?? ""}
              disabled={!editable}
              className="form-control inherit-font-size"
              placeholder="Part Name"
            />
          </td>
          <td className="lc-column maintenance">
            <label>Part Cost</label>
            <input
              type={"number"}
              name="part_cost"
              onChange={(event) => this.setPartCost(event.target.valueAsNumber) }
              value={part_cost > 0 ? (part_cost / 100) : ""}
              disabled={!editable}
              className="form-control inherit-font-size"
              placeholder="Part Cost"
            />
          </td>
          {/* {canRemove && editable && (
            <td className="lc-column maintenance remove-line-item-wrapper">
              <a className="remove-line-item" href="" onClick={this.remove}>
                &times;
              </a>
            </td>
          )*/}
        </tr>
        <tr key={id + "data2"} className={wrapperClass} style={{ backgroundColor: "white" }}>
          <td className="lc-column maintenance">
            <label>Part Number</label>
            <input
              name="part_number"
              type={"text"}
              onChange={(event) =>
                this.setPartDetail("part_number", event.target.value)
              }
              value={part_number ?? ""}
              disabled={!editable}
              className="form-control inherit-font-size"
              placeholder="Part Number"
            />
          </td>
        </tr>
        <tr key={id + "data3"} className={wrapperClass}>
          <td className="lc-column maintenance">
            <label>Part Description</label>
            <textarea
              name="part_description"
              className="form-control w-100"
              aria-label="With textarea"
              placeholder="Write part description here"
              value={part_description || ""}
              onChange={(event) =>
                this.setPartDetail("part_description", event.target.value)
              }
            />
          </td>
        </tr>
      </>
    );
  }
}

export default MaintenaceLineItem;
