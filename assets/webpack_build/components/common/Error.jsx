import React, { PureComponent } from 'react';

class Error extends PureComponent {
  render() {
    const { text } = this.props;

    if (!text) return null;

    return <span className="react-form-error">${text}</span>
  }
}

export default Error;
