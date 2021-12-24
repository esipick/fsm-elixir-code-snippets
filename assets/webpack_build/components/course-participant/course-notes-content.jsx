import React, { useEffect, useState } from "react";
import { authHeaders } from "./../utils";
import { Spinner } from "./common/spinner";

export const CourseNotesContent = ({ participant }) => {
  return (
    <div className="course-notes">
      <h4 className="m-0">Course Notes</h4>
      <div className="lesson">
        {(participant.lessons ?? []).map((lesson, index) => {
          return (
            <div key={lesson.id}>
              {/* auto load notes for first two lessons */}
              <LessonNotes
                lesson={lesson}
                autoLoading={index < 2 ? true : false}
                courseId={participant.courseId}
                lmsUserId={participant.user_id}
              />
            </div>
          );
        })}
      </div>
    </div>
  );
};

const LessonNotes = ({ lesson, courseId, lmsUserId, autoLoading }) => {
  const [state, setState] = useState({
    sublessons: [],
    loadingSublessons: autoLoading,
  });

  useEffect(() => {
    const fetchSublessons = () => {
      const payload = {
        course_id: courseId,
        lms_user_id: lmsUserId,
        section_id: lesson.section_id,
      };

      const reqOpts = {
        method: "POST",
        headers: {
          ...authHeaders(),
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      };

      fetch("/api/course/lesson/sublessons", reqOpts)
        .then((res) => res.json())
        .then(
          (res) => {
            setState((prevState) => ({
              ...prevState,
              sublessons: res.data,
              loadingSublessons: false,
            }));
          },
          (error) => {
            console.log(error);
            setState((prevState) => ({
              ...prevState,
              loadingSublessons: false,
            }));
          }
        );
    };

    if (state.loadingSublessons) {
      fetchSublessons();
    }
  }, [lesson, courseId, lmsUserId, state.loadingSublessons]);

  return (
    <>
      <p
        className="title my-2 cursor-pointer"
        onClick={() =>
          setState((prevState) => ({
            ...prevState,
            loadingSublessons: true,
          }))
        }
      >
        {lesson.name}
      </p>
      {state.loadingSublessons ? (
        <div className="text-center my-2">
          <Spinner />
        </div>
      ) : (
        (state.sublessons ?? []).map((sl) => {
          if (!sl.notes) {
            return null;
          }
          return (
            <div key={lesson.id + "-" + sl.id} className="p-1">
              <p className="bold m-0">{sl.name}</p>
              <div style={{ whiteSpace: "pre-line" }}> {sl.notes}</div>
            </div>
          );
        })
      )}
    </>
  );
};
