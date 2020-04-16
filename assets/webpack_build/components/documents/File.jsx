import React, { Component } from 'react'

class File extends Component {
  constructor(props) {
    super(props)
  }

  handleChange = () => {
    const { id, updateCheckboxes } = this.props
    updateCheckboxes(id)
  }

  delete = (e) => {
    e.preventDefault();
    const { id, onRemove } = this.props
    onRemove(id)
  }

  rowMessage = (className) => {
    if (className == "eq") {
      return 'Need attention'
    } else if (className == "lt") {
      return 'Expired'
    }
  }

  render() {
    const { admin, checked, expires_date, expired, file_name, file_url, id } = this.props
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
          <a href={file_url}
            rel='noopener noreferrer'
            target='_blank'
            title={file_name}>
            <i className="icon now-ui-icons arrows-1_cloud-download-93"></i>
            <div className="link-content">
              <h3>{file_name}</h3>
              {expires_date &&
                <p className="mobile">Expires: {expires_date}</p>
              }
              <p className="message mobile">{message}</p>
            </div>
          </a>
        </div>
        <div className="th expiry-col full-width desktop">
          <p>{expires_date}</p>
        </div>
        {admin &&
          <div className="th action-col desktop">
            <a className="delete now-ui-icons ui-1_simple-remove" href="" onClick={this.delete} title="delete" />
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
      </div>
    )
  }
}

export default File
