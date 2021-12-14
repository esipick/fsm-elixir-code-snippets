import React from "react";

export const Spinner = ({ borderColor }) => {
  return (
    <div className="lds-ring">
      <div style={{ borderColor }}></div>
      <div></div>
      <div></div>
      <div></div>
    </div>
  );
}
