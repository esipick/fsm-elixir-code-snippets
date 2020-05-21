import React, { Component, forwardRef } from 'react'
import DatePicker from 'react-datepicker'
import Error from '../common/Error'

class SelectedFile extends Component {
  constructor(props) {
    super(props)

    this.state = {
      date: new Date(),
      hideDatePickerValue: true
    }
  }

  addExpiryDate = (date) => {
    const { addExpiryDate, file: { path } } = this.props
    addExpiryDate(path, date.toISOString())
    this.setState({ date, hideDatePickerValue: false })
  }

  cancel = () => {
    const { cancel, file: { path } } = this.props
    cancel(path)
  }

  displaySize = (bytes) => {
    const megabytes = bytes / 1000 / 1000
    return `${megabytes.toFixed(2)} MB`
  }

  hideExpiryDate = () => {
    const { removeExpiryDate, file: { path } } = this.props

    removeExpiryDate(path)
    this.setState({ date: new Date(), hideDatePickerValue: true })
  }

  render() {
    const { dispalyExpiryDate, errors, file: { name, path, size } } = this.props
    const { date, hideDatePickerValue } = this.state
    const error = errors.find(error => error.path == path) || { messages: {} }
    const CustomExpiryDateInput = forwardRef(({ onClick, value, hidden }, ref) => (
      <div className="expiry-date-container" ref={ref}>
        <div className="expiry-date-input" onClick={onClick}>
          <span>Select expiry date</span>
          <i className="now-ui-icons ui-1_calendar-60"></i>
          <span hidden={hidden}>{dispalyExpiryDate(value)}</span>
        </div>
        <span className="clear now-ui-icons ui-1_simple-remove" hidden={hidden} onClick={this.hideExpiryDate}></span>
      </div>
    ))

    return (
      <div className="selected-file">
        <div className="file-content">
          <div className="icon">
            <div className="now-ui-icons design_image"></div>
          </div>
          <div className="description">
            <h3>{name}</h3>
            <p>{this.displaySize(size)}</p>
          </div>
          <div className="remove-button now-ui-icons ui-1_simple-remove"
            onClick={this.cancel} />
        </div >
        <DatePicker onChange={this.addExpiryDate}
          minDate={new Date()}
          customInput={<CustomExpiryDateInput hidden={hideDatePickerValue} />}
          selected={date} />
        <div className="errors">
          <Error text={error.messages.file} />
        </div>
      </div >
    )
  }
}

export default SelectedFile
