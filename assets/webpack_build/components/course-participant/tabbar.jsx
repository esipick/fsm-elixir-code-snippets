import React, { useState } from "react";

export const Tabbar = ({ showCourseNotes }) => {
  return (
    <Wrapper>
      <Tab key="course-notes" callback={showCourseNotes} />
    </Wrapper>
  );
};

function Tab({ callback }) {
  const [hovered, setHovered] = useState(false);
  return (
    <div
      onClick={callback}
      onMouseEnter={() => setHovered(!hovered)}
      onMouseLeave={() => setHovered(!hovered)}
      className="tab align-items-center cursor-pointer d-flex flex-row mx-4 cursor-pointer"
    >
      <div
        className={`icon border mr-2 round-button ${
          hovered ? "bg-secondary" : ""
        }`}
      >
        <img src={"/images/note.svg"} className="" height="25px" width="25px" />
      </div>
      <p className={`text-white mb-0 title ${hovered ? "text-secondary" : ""}`}>
        COURSE NOTES
      </p>
    </div>
  );
}

function Wrapper({ children }) {
  return (
    <div className="lesson-tabs d-flex flex-row align-items-center bg-dark p-2">
      {children}
    </div>
  );
}
