import React, { PureComponent } from 'react';

class Error extends PureComponent {
  render() {
    let { text } = this.props;

    if (!text) return null;

    text = Array.isArray(text) ? text[0] : text

    return <span className="react-form-error">{text}</span>
  }
}

export default Error;
