import http from 'j-fetch'
import React, { Component } from 'react'
import Pagination from "react-js-pagination";
import Dropzone from 'react-dropzone'
import File from './File'
import SelectedFile from './SelectedFile'
import { authHeaders } from '../utils'

class Main extends Component {
  constructor(props) {
    super(props)

    const { documents, page_number, page_size, total_entries, total_pages } = this.props

    this.state = {
      acceptedFiles: [],
      allCheckboxSelected: false,
      checkboxes: [],
      documents: documents,
      dropzone: documents.length == 0,
      errors: [],
      expiryDates: [],
      page_number: page_number,
      page_size: page_size,
      search: '',
      total_entries: total_entries,
      total_pages: total_pages
    }
  }

  removeExpiryDate = (path) => {
    const { expiryDates } = this.state
    const filteredExpiryDates = expiryDates.filter(date => date.path != path)

    this.setState({ expiryDates: filteredExpiryDates })
  }

  addExpiryDate = (path, date) => {
    let { expiryDates } = this.state
    expiryDates.push({ path, date })
    this.setState({ expiryDates })
  }

  allCheckboxesClick = () => {
    const { checkboxes, documents } = this.state
    let selectedCheckboxes = []

    if (checkboxes.length < documents.length) {
      for (let document of documents) {
        selectedCheckboxes.push(document.id)
      }
    } else { selectedCheckboxes = [] }

    this.setState({ checkboxes: selectedCheckboxes })
  }

  acceptFiles = (acceptedFiles) => {
    this.setState({ acceptedFiles })
  }

  cancel = (path) => {
    const { acceptedFiles } = this.state
    const filtered = acceptedFiles.filter(file => file.path != path)

    this.setState({ acceptedFiles: filtered })
    this.removeExpiryDate(path)
  }

  closeDropzone = () => {
    this.setState({ dropzone: false })
  }

  deleteSelectedDocuments = () => {
    const { checkboxes } = this.state

    if (checkboxes == []) return

    for (let id of checkboxes) {
      this.removeDocument(id)
    }

    this.setState({ allCheckboxSelected: false, checkboxes: [] })
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

  getDocuments = ({ page_number = 1, search = '' }) => {
    const { user_id } = this.props
    this.setState({ page_number, search })

    let url = `/api/users/${user_id}/documents?page=${page_number}`

    if (search != '') {
      url = url + `&search=${search}`
    }

    fetch(url, {
      headers: authHeaders(),
      method: 'GET'
    }).then(response => {
      response.json().then(({ documents, page_number, page_size, total_entries, total_pages }) => {
        this.setState({ documents, dropzone: total_entries == 0, page_number, page_size, total_entries, total_pages })
        return { total_entries }
      })
    }).catch(response => {
      response.json().then(({ errors = {} }) => {


        this.setState({ saving: false, errors })
      })
    })
  }

  handleCheckboxChange = () => {
    const { allCheckboxSelected, checkboxes, documents } = this.state
    let checkbox = allCheckboxSelected
    let selectedCheckboxes = []

    if (checkboxes.length < documents.length) {
      for (let document of documents) {
        selectedCheckboxes.push(document.id)
      }
      document.getElementById('allCheckbox').checked = true
      checkbox = true
    } else {
      checkbox = false
      selectedCheckboxes = []
    }

    this.setState({ allCheckboxSelected: checkbox, checkboxes: selectedCheckboxes })
  }

  handleSearch = (e) => {
    const value = e.target.value
    this.setState({ search: value })
    this.getDocuments({ search: value })
  }

  openDropzone = () => {
    this.setState({ dropzone: true })
  }

  removeDocument = (id) => {
    const { user_id } = this.props

    const school_span = document.getElementById("current-school")
    let url = `/api/users/${user_id}/documents/${id}`

    if (school_span) {
      url = url + `?school_id=${school_span.dataset['schoolId']}`
    }

    console.log(url)
    http['delete']({
      url: url,
      headers: authHeaders()
    }).then(response => {
      if (response.status == 204) {
        this.getDocuments({})
      }
    })
  }

  setPage = (page_number) => {
    this.getDocuments({ page_number: page_number })
  }

  submit = () => {
    const { acceptedFiles, expiryDates, saving } = this.state
    if (saving) return

    const { user_id } = this.props
    this.setState({ allCheckboxSelected: false, checkboxes: [], saving: true })

    for (let file of acceptedFiles) {
      const formData = new FormData()
      const expiryDate = expiryDates.find(date => date.path == file.path)

      formData.append('document[file]', file, file.name)

      if (expiryDate) {
        formData.append('document[expires_at]', expiryDate.date)
      }

      const school_span = document.getElementById("current-school")
      let url = `/api/users/${user_id}/documents`

      if (school_span) {
        url = url + `?school_id=${school_span.dataset['schoolId']}`
      }

      fetch(url, {
        body: formData,
        headers: authHeaders(),
        method: 'POST'
      }).then(response => {
        if (response.status == 200) {
          response.json().then(() => {
            this.getDocuments({})
            this.setState({
              acceptedFiles: [],
              dropzone: false,
              expiryDate: new Date(),
              expiryDates: [],
              hideDatePickerValue: true,
              saving: false
            })
          })
        } else {
          response.json().then(({ errors = {} }) => {
            let stateErrors = this.state.errors
            stateErrors.push({ path: file.path, messages: errors })
            this.setState({ saving: false, errors: stateErrors })
          })
        }
      }).catch(response => {
        response.json().then(({ errors = {} }) => {
          this.setState({ saving: false, errors })
        })
      })
    }
  }

  updateCheckboxes = (id) => {
    const { allCheckboxSelected, checkboxes, documents } = this.state
    let checkbox = allCheckboxSelected
    let selected = checkboxes

    if (checkboxes.includes(id)) {
      checkbox = false
      selected = selected.filter(item => item != id)
    } else {
      selected.push(id)
    }

    if (selected.length == documents.length) {
      checkbox = true
    }

    this.setState({ allCheckboxSelected: checkbox, checkboxes: selected })
  }

  render() {
    const { acceptedFiles, allCheckboxSelected, checkboxes, documents, dropzone, errors,
      search, page_number, page_size, total_entries, total_pages, saving } = this.state
    const { admin } = this.props

    return (
      <div className="documents">
        {
          admin && dropzone ? (
            acceptedFiles.length ? (
              <div className="form">
                {acceptedFiles.map((file) => (
                  <SelectedFile addExpiryDate={this.addExpiryDate}
                    cancel={this.cancel}
                    dispalyExpiryDate={this.dispalyExpiryDate}
                    errors={errors}
                    file={file}
                    key={file.path}
                    removeExpiryDate={this.removeExpiryDate}>
                  </SelectedFile>
                ))}
                <div className="action">
                  <button className="btn btn-primary"
                    disabled={saving}
                    onClick={this.submit}>
                    Upload files
                  </button>
                </div>
              </div >
            ) : (
                <Dropzone maxFiles={1}
                  accept=".jpeg,.jpg,.png,.pdf"
                  maxSize={5000000}
                  onDrop={this.acceptFiles}>
                  {({ getRootProps, getInputProps }) => (
                    <div className="dropzone"
                      {...getRootProps()}>
                      <input {...getInputProps()} />
                      <div className="button">
                        <p>Drag & Drop a file to upload it.</p>
                        <p className="dropzone-description">Allowed file types: .jpeg, .jpg, .png, .pdf.</p>
                        <p className="dropzone-description">Max size: 5MB</p>
                        <p>
                          <button className="btn btn-primary">
                            Browse Files
                          </button>
                        </p>
                      </div>
                    </div>
                  )}
                </Dropzone>
              )
          ) : (
              <div className="table table m-0">
                <div className="row bar m-0">
                  <div className="col-md-4 col-xs-12 desktop">
                    {admin && checkboxes.length > 0 &&
                      <button className="btn btn-danger"
                        onClick={(e) => { if (window.confirm('Are you sure you wish to delete selected documents?')) this.deleteSelectedDocuments(e) }}>
                        Delete
                    </button>
                    }
                  </div>
                  <div className="col-md-4 col-xs-12 search-col">
                    <div className="form-group m-0">
                      <img src="/images/search.svg" />
                      <input className="form-control"
                        onChange={this.handleSearch}
                        placeholder="Search"
                        type="search"
                        value={search} />
                    </div>
                  </div>
                  <div className="col-md-4 col-xs-12 desktop">
                    {admin &&
                      <div className="form-group m-0 d-flex flex-row-reverse p-0">
                        <button className="btn btn-primary"
                          onClick={this.openDropzone}>+ Add new document</button>
                      </div>
                    }
                  </div>
                </div>
                {documents.length ? (
                  <div className="files">
                    <div className="row m-0 desktop">
                      {admin &&
                        <div className="th checkbox-col">
                          <div className="checkbox">
                            <input checked={allCheckboxSelected}
                              id="allCheckbox"
                              onChange={this.handleCheckboxChange}
                              type="checkbox" />
                            <label htmlFor="allCheckbox" />
                          </div>
                        </div>
                      }
                      <div className="th full-width file-col">
                        <h2>Document</h2>
                      </div>
                      <div className="th full-width expiry-col desktop">
                        <h2>Expiry date</h2>
                      </div>
                      {admin &&
                        <div className="th action-col desktop">
                          <h2>Actions</h2>
                        </div>
                      }
                      <div className="th warning-col"></div>
                    </div>
                    {documents.map((document) => (
                      <File admin={admin}
                        checked={checkboxes.includes(document.id)}
                        expired={document.expired}
                        expires_date={this.dispalyExpiryDate(document.expires_at)}
                        id={document.id}
                        file_name={document.file_name}
                        file_url={document.file_url}
                        key={document.id}
                        onRemove={(e) => { if (window.confirm('Are you sure you wish to delete this document?')) this.removeDocument(e) }}
                        updateCheckboxes={this.updateCheckboxes}>
                      </File>
                    ))}
                    {total_pages > 1 &&
                      <Pagination activePage={page_number}
                        itemClass="page-item"
                        itemsCountPerPage={page_size}
                        linkClass="page-link"
                        onChange={this.setPage}
                        pageRangeDisplayed={5}
                        totalItemsCount={total_entries} />}
                  </div>
                ) : (
                    <div className="files">
                      <div className="row m-0">
                        <p>No documents found</p>
                      </div>
                    </div>
                  )}
              </div>
            )}
      </div>)
  }
}

export default Main
