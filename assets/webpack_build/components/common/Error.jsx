import React, { PureComponent } from 'react';
import classnames from 'classnames';

class Error extends PureComponent {
  render() {
    let { text, styleProps } = this.props;

    if (!text) return null;

    text = Array.isArray(text) ? text[0] : text;

    const klassName = classnames(this.props.className, 'react-form-error');

    return <span className={klassName} style={styleProps || {}}>{text}</span>
  }
}

export default Error;
