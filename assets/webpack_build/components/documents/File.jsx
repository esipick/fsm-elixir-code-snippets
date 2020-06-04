import React, { Component } from 'react'

class File extends Component {
  constructor(props) {
    super(props)

    this.state = {
      showImg: false
    }
  }

  handleChange = () => {
    const { id, updateCheckboxes } = this.props
    updateCheckboxes(id)
  }

  delete = (e) => {
    e.preventDefault()
    const { id, onRemove } = this.props
    onRemove(id)
  }

  edit = (e) => {
    e.preventDefault()
    const { editDocument, id } = this.props
    editDocument(id)
  }

  rowMessage = (className) => {
    if (className == "eq") {
      return 'Need attention'
    } else if (className == "lt") {
      return 'Expired'
    }
  }

  showDocument = () => {
    const { file: { name, url } } = this.props
    const type = name.split(".").slice(-1)[0].toLowerCase()

    if (type == "pdf") {
      window.open(url)
    } else {
      this.setState({ showImg: true })
    }
  }

  closeImg = () => {
    this.setState({ showImg: false })
  }

  deleteExpiryDate = () => {
    const { id, updateExpiryDate } = this.props
    updateExpiryDate(id, '')
  }

  setExpiryDate = (date) => {
    const { id, updateExpiryDate } = this.props
    updateExpiryDate(id, date.toISOString())
  }

  render() {
    const { admin, checked, expires_at, expired, file: { name, url }, id, title } = this.props
    const { showImg } = this.state
    const htmlId = 'checkbox-' + id
    const message = this.rowMessage(expired)

    return (
      <div className={"row file" + ` ${expired}`}>
        {admin &&
          <div className="th checkbox-col desktop">
            <div className="checkbox">
              <input checked={checked}
                onChange={this.handleChange}
                id={htmlId}
                ref={id}
                type="checkbox" />
              <label htmlFor={htmlId} />
            </div>
          </div>
        }
        <div className="th file-col full-width">
          <div className="icon" onClick={this.showDocument}>
            {name.endsWith('.pdf') &&
              <img src="/images/pdf.svg" />
            }
            {!name.endsWith('.pdf') &&
              <img src={url} />
            }
          </div>
          <div title={title}>
            <div className="link-content">
              <h3>{title}</h3>
              {expires_at &&
                <p className="mobile">Expires: {expires_at}</p>
              }
              <p className="message mobile">{message}</p>
            </div>
          </div>
        </div>
        <div className="th expiry-col full-width desktop">
          <p>{expires_at}</p>
        </div>
        {admin &&
          <div className="th action-col desktop">
            <div className="buttons">
              <a className="action" href="" onClick={this.edit} title="edit">
                <img src="/images/pencil.svg" />
              </a>
              <a className="action" href="" onClick={this.delete} title="delete">
                <img src="/images/trash.svg" />
              </a>
            </div>
          </div>
        }
        <div className="th warning-col">
          {expired == 'eq' &&
            <img src="/images/alert.svg" />
          }
          {expired == 'lt' &&
            <img src="/images/warning.svg" />
          }
        </div>
        {
          showImg &&
          <div className="modal-image">
            <div id="close-img-popup" onClick={this.closeImg}>&times;</div>
            <div className="image-wrapper">
              <div id="caption">{title}</div>
              <img className="modal-content-img" src={url} />
            </div>
          </div>
        }
      </div>
    )
  }
}

export default File
