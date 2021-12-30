import React from "react";
import { ChevronRight } from "./../common/icons";
import { RemarksButtons } from "./../common/remarks-buttons";

export const SubLessonCard = ({
  lesson,
  sublesson,
  selected,
  setSublesson,
  markedSublesson,
  participant,
  saveRemarks,
}) => {
  return (
    <div
      className={`row py-1 ml-1 d-flex flex-row justify-content-between no-last-child-border border-bottom 
        ${selected || markedSublesson.sublessonId ? "bg-light" : ""} ${
        markedSublesson.sublessonId ? "disabled-click text-secondary" : ""
      }`}
    >
      <div
        className="d-flex flex-row justify-content-start align-items-center"
        id={`heading${lesson.id}-${sublesson.id}`}
      >
        <div
          onClick={setSublesson}
          className="cursor-pointer d-flex flex-row justify-content-start align-items-center"
        >
          <ChevronRight />
          <h5
            className={`mb-0 ${
              markedSublesson.sublessonId ? "text-secondary" : "text-dark"
            }`}
          >
            {sublesson.name}
          </h5>
        </div>
      </div>
      <RemarksButtons
        {...{ markedSublesson, sublesson, saveRemarks, studentOrRenter: participant.studentOrRenter }}
      />
    </div>
  );
};
