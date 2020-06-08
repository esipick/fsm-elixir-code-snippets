import React, { Component, forwardRef } from 'react'
import DatePicker from 'react-datepicker'
import Error from '../common/Error'

class SelectedFile extends Component {
  constructor(props) {
    super(props)

    const { document: { expires_at, file, title } } = this.props
    const today = new Date()

    this.state = {
      date: expires_at ? (new Date(expires_at)) : (today),
      file: file,
      hideDatePickerValue: !expires_at,
      title: title,
      today: today
    }
  }

  cancel = () => {
    const { cancel, document: { id } } = this.props
    cancel(id)
  }

  dispalyExpiryDate = (expiryDate) => {
    if (expiryDate) {
      const options = { month: "long", day: "numeric", year: "numeric" }
      const date = new Date(expiryDate)
      const americanDate = new Intl.DateTimeFormat("en-US", options).format(date)

      return americanDate
    }
    else { return '' }
  }

  displaySize = (bytes) => {
    const megabytes = bytes / 1000 / 1000
    return `${megabytes.toFixed(2)} MB`
  }

  hideExpiryDate = () => {
    const { document: { id }, updateDocumentsToSubmit } = this.props
    const { file, title } = this.state

    this.setState({ date: new Date(), hideDatePickerValue: true })
    updateDocumentsToSubmit({ file, id, title })
  }

  onDateChange = (date) => {
    const { document: { file, id, title }, updateDocumentsToSubmit } = this.props

    this.setState({ date, hideDatePickerValue: false })
    updateDocumentsToSubmit({ expires_at: date.toISOString(), file, id, title })
  }

  onFileChange = (e) => {
    const { document: { expires_at, id, title }, updateDocumentsToSubmit } = this.props
    let file = e.target.files[0]
    file.path = file.name

    this.setState({ file, title })
    updateDocumentsToSubmit({ expires_at, file, id, title })
  }

  onTitleChange = (e) => {
    const { document: { expires_at, file, id }, updateDocumentsToSubmit } = this.props
    const title = e.target.value

    this.setState({ title: title })
    updateDocumentsToSubmit({ expires_at, file, id, title })
  }

  render() {
    const { errors, document: { id } } = this.props
    const { date, hideDatePickerValue, file, title, today } = this.state
    const error = errors.find(error => error.id == id) || { messages: {} }
    const CustomExpiryDateInput = forwardRef(({ onClick, value, hidden }, ref) => (
      <div className="expiry-date-container" ref={ref}>
        <div className="expiry-date-input" onClick={onClick}>
          <span>Select expiry date</span>
          <i className="now-ui-icons ui-1_calendar-60"></i>
          <span hidden={hidden}>{this.dispalyExpiryDate(value)}</span>
        </div>
        <span className="clear now-ui-icons ui-1_simple-remove" hidden={hidden} onClick={this.hideExpiryDate}></span>
      </div>
    ))

    return (
      <div className="selected-file">
        <div className="file-content">
          <div className="icon">
            {file && (file.name.endsWith('.pdf') ? (
              <img src="/images/pdf.svg" />
            ) : (
                <img src={file.url} />
              )
            )}
            {!file.url && <div className="now-ui-icons design_image"></div>}
            <div className="upload-file">
              <label>
                <input onChange={this.onFileChange} type="file" />
              </label>
            </div>
          </div>
          <div className="description">
            <input onChange={this.onTitleChange} type="text" value={title} />
            {file.size &&
              <p>{file.name + ' - ' + this.displaySize(file.size)}</p>
            }
          </div>
          <div className="remove-button now-ui-icons ui-1_simple-remove"
            onClick={this.cancel} />
        </div>
        <DatePicker onChange={this.onDateChange}
          minDate={today}
          customInput={<CustomExpiryDateInput hidden={hideDatePickerValue} />}
          selected={date} />
        <div className="errors">
          <Error text={error.messages.file} />
        </div>
      </div>
    )
  }
}

export default SelectedFile
