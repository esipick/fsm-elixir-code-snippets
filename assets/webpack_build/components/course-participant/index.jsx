import React, { useState } from "react";
import { CourseLesson } from "./lesson/index";
// import { Tabbar } from "./tabbar";

import { isStudentOrRenter } from "./utils";

export const CourseParticipant = ({
  participantCourse,
  userRoles,
  courseId,
}) => {

  const [state, setState] = useState({
    lesson: undefined,
    sublesson: undefined,
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
      {/* <InnerWrapper>
        <Tabbar />
      </InnerWrapper> */}
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
