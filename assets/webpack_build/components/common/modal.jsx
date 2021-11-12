import React from "react";
import { createPortal } from "react-dom";

export const Modal = ({ children, callback }) => {
  return createPortal(
    <div
      className="modal fade show d-block"
      tabIndex={-1}
      style={{ paddingRight: "15px" }}
      role="dialog"
      id="reactAppModal"
    >
      <div className="modal-dialog" role="document">
        <div className="modal-content">
          <div className="modal-header" onClick={callback}>
            <button
              type="button"
              className="close cursor-pointer"
              style={{ top: "10px" }}
              aria-label="Close"
            >
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div className="modal-body">{children}</div>
        </div>
      </div>
    </div>,
    document.body
  );
};
