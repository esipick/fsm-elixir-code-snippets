import http from 'j-fetch'
import React, { Component } from 'react'
import Pagination from "react-js-pagination"
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
      documentsToSubmit: [],
      dropzone: documents.length == 0,
      errors: [],
      page_number: page_number,
      page_size: page_size,
      search: '',
      total_entries: total_entries,
      total_pages: total_pages
    }
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
    const documentsToSubmit = acceptedFiles.map((file, i) => ({
      id: i,
      file: file,
      fresh: true,
      title: file.path,
      tempUrl: URL.createObjectURL(file)
    }))

    this.setState({ documentsToSubmit })
  }

  cancel = (id) => {
    const { documentsToSubmit, total_entries } = this.state
    const filteredDocumentsToSubmit = documentsToSubmit.filter(document => document.id != id)

    this.setState({ documentsToSubmit: filteredDocumentsToSubmit, dropzone: total_entries.length == 0 })
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

  getDocuments = ({ page_number = 1, search = '' }) => {
    const { user_id } = this.props
    this.setState({ page_number, search })

    let url = '/api/users/' + user_id + '/documents?page=' + page_number

    if (search != '') {
      url = url + '&search=' + search
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
    let url = '/api/users/' + user_id + '/documents/' + id

    if (school_span) {
      url = url + '?school_id=' + school_span.dataset['schoolId']
    }

    http['delete']({
      url: url,
      headers: authHeaders()
    }).then(response => {
      if (response.status == 204) {
        this.getDocuments({})
      }
    })
  }

  updateDocumentsToSubmit = (document) => {
    const { documentsToSubmit } = this.state
    let changed_document = documentsToSubmit.find(d => d.id == document.id)

    if (changed_document) {
      changed_document.expires_at = document.expires_at
      changed_document.file = document.file
      changed_document.title = document.title
    } else {
      documentsToSubmit.push(document)
    }
  }

  setPage = (page_number) => {
    this.getDocuments({ page_number: page_number })
  }

  editDocument = (id) => {
    const { documents } = this.state
    const documentsToSubmit = documents.filter(document => document.id == id).map(({ expires_at, file, id, title }) => (
      { expires_at: expires_at ? (new Date(expires_at).toISOString()) : (''), id, file, title }
    ))

    this.setState({ allCheckboxSelected: false, checkboxes: [], documentsToSubmit: documentsToSubmit })
  }

  setDocumentsToSubmit = () => {
    const { checkboxes, documents } = this.state
    const documentsToSubmit = documents.filter(document => checkboxes.includes(document.id)).map(({ expires_at, file, id, title }) => (
      { expires_at: expires_at ? (new Date(expires_at).toISOString()) : (''), id, file, title }
    ))

    this.setState({ allCheckboxSelected: false, checkboxes: [], documentsToSubmit: documentsToSubmit })
  }

  submit = () => {
    const { documentsToSubmit, saving } = this.state
    const school_span = document.getElementById("current-school")

    if (saving) return

    const { user_id } = this.props
    this.setState({ allCheckboxSelected: false, checkboxes: [], saving: true })

    for (let { expires_at, file, fresh, id, title } of documentsToSubmit) {
      const formData = new FormData()
      const method = fresh ? ('POST') : ('PATCH')

      let url = '/api/users/' + user_id + '/documents'

      if (!fresh) {
        url = url + '/' + id
      }

      if (school_span) {
        url = url + '?school_id=' + school_span.dataset['schoolId']
      }
      formData.append('document[title]', title)
      formData.append('document[expires_at]', expires_at ? (expires_at) : (''))

      if (file.path) {
        formData.append('document[file]', file, file.name)
      }

      fetch(url, {
        body: formData,
        headers: authHeaders(),
        method: method
      }).then(response => {
        if (response.status == 200) {
          this.getDocuments({})
          this.setState({
            documentsToSubmit: [],
            dropzone: false,
            hideDatePickerValue: true,
            saving: false
          })
        } else {
          response.json().then(({ errors }) => {
            let stateErrors = this.state.errors
            stateErrors.push({ id: id, messages: errors })
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

  adminDropzone = () => {
    const { documentsToSubmit } = this.state;

    if (documentsToSubmit.length) return this.uploadForm();

    const fileSize = 10 * 1048576;

    return (
      <Dropzone maxFiles={1}
        accept=".jpeg,.jpg,.png,.pdf"
        maxSize={fileSize}
        onDrop={this.acceptFiles}>
        {({ getRootProps, getInputProps }) => (
          <div className="dropzone"
            {...getRootProps()}>
            <input {...getInputProps()} />
            <div className="button">
              <p>Drag &amp; Drop a file to upload it.</p>
              <p className="dropzone-description">Allowed file types: .jpeg, .jpg, .png, .pdf.</p>
              <p className="dropzone-description">Max size: 10MB</p>
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
  }

  documentsTable = () => {
    const { allCheckboxSelected, checkboxes, documents, dropzone, documentsToSubmit,
      errors, search, page_number, page_size, total_entries, total_pages, saving } = this.state
    const { admin } = this.props;

    return (
      <div className="table table m-0">
        <div className="row bar m-0">
          <div className="col-md-4 col-xs-12 desktop">
            {admin && checkboxes.length > 0 &&
              <div>
                <button className="btn btn-danger"
                  onClick={(e) => { if (window.confirm('Are you sure you wish to delete selected documents?')) this.deleteSelectedDocuments(e) }}>
                  Delete
            </button>
                <button className="btn btn-primary ml-3"
                  onClick={this.setDocumentsToSubmit}>
                  Edit
            </button>
              </div>
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
            {documents.map(document => (
              <File admin={admin} checkboxes
                checkboxes={checkboxes}
                checked={checkboxes.includes(document.id)}
                editDocument={this.editDocument}
                expired={document.expired}
                expires_at={document.expires_at}
                file={document.file}
                id={document.id}
                key={document.id}
                onRemove={(e) => { if (window.confirm('Are you sure you wish to delete this document?')) this.removeDocument(e) }}
                title={document.title}
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
          )
        }
      </div>
    )
  }

  uploadForm = (options = {}) => {
    const { documentsToSubmit, errors, saving } = this.state;

    return (
      <div className="form">
        <div className={options.wrapperClass}>
          {documentsToSubmit.map(document => (
            <SelectedFile cancel={this.cancel}
              document={document}
              errors={errors}
              key={document.id}
              updateDocumentsToSubmit={this.updateDocumentsToSubmit}>
            </SelectedFile>
          ))}
        </div>
        <div className="action">
          <button className="btn btn-primary"
            disabled={saving}
            onClick={this.submit}>
            Update
            </button>
        </div>
      </div>
    )
  }

  render() {
    const { allCheckboxSelected, checkboxes, documents, dropzone, documentsToSubmit,
      errors, search, page_number, page_size, total_entries, total_pages, saving } = this.state
    const { admin } = this.props;

    return (
      <div className="documents">
        {admin && dropzone && this.adminDropzone()}

        {!dropzone && (documentsToSubmit.length ? this.uploadForm({wrapperClass: "files"}) : this.documentsTable())}
      </div>
    )
  }
}

export default Main
