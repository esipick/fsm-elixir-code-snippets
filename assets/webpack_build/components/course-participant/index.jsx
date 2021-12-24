import React, { useState } from "react";
import { Modal } from "../common/modal";
import { CourseNotesContent } from "./course-notes-content";
import { CourseLesson } from "./lesson/index";
import { Tabbar } from "./tabbar";

import { isStudentOrRenter } from "./utils";

export const CourseParticipant = ({
  participantCourse,
  userRoles,
  courseId,
}) => {

  const [state, setState] = useState({
    lesson: undefined,
    sublesson: undefined,
    openCourseNotes: false
  });

  if ((participantCourse.lessons ?? []).length === 0) {
    return (
      <Wrapper>
        <InnerWrapper>
          <h4 className="row justify-content-center text-secondary mt-0">
            Lessons Not Found
          </h4>
        </InnerWrapper>
      </Wrapper>
    );
  }

  return (
    <Wrapper>
      <InnerWrapper>
        <Tabbar showCourseNotes={() => setState((prevState) => ({...prevState, openCourseNotes: !prevState.openCourseNotes}))} />
      </InnerWrapper>
      {participantCourse.lessons.map((lesson, index) => {
        return (
          <CourseLesson
            key={lesson.id + "-" + index}
            lesson={lesson}
            participant={{
              ...participantCourse,
              courseId: parseInt(courseId),
              studentOrRenter: isStudentOrRenter(userRoles),
            }}
          />
        );
      })}
      {
      participantCourse.lessons.length > 0 && state.openCourseNotes && (
        <Modal callback={() => setState((prevState) => ({...prevState, openCourseNotes: !state.openCourseNotes})) }>
           <CourseNotesContent participant={{
              ...participantCourse,
              courseId: parseInt(courseId),
              studentOrRenter: isStudentOrRenter(userRoles)
           }} />
        </Modal>
      )
      }
    </Wrapper>
  );
};

function Wrapper({ children }) {
  return (
    <div className="card">
      <div className="card-header d-flex flex-column">{children}</div>
    </div>
  );
}

function InnerWrapper({ children, className }) {
  return (
    <div className={`row lesson-content my-1 ${className}`}>
      <div className="col-md-12 border-secondary">{children}</div>
    </div>
  );
}
