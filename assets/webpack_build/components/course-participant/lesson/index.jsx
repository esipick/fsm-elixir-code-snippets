import React, { useEffect, useState } from "react";
import { ChevronDown, ChevronUp } from "./../common/icons";
import { Spinner } from "./../common/spinner";
import { Modal } from "./../../common/modal";
import { authHeaders } from "./../../utils";
import { MapRemarksType, RemarksType, SubLessonTypes } from "./../constants";
import { SubLessonCard } from "./../sublesson/index";
import { LessonNotesModalContent } from "./notes-modal-content";
import { SubLessonSidePanel } from "../sublesson/sidepanel";
import { mergeSublessons } from "../utils";

export const CourseLesson = ({ lesson, participant }) => {
  const [state, setState] = useState({
    sublessons: undefined, // this must be { }
    selectedSublesson: undefined,
    loadingSublessons: false,
    openNotesModal: false,
    openOverviewModal: false,
  });

  const toggleLessonContent = () => {
    // if sublessons already loaded - do toggle
    if (state.sublessons) {
      return setState((prevState) => ({
        ...prevState,
        sublessons: undefined,
        selectedSublesson: undefined,
      }));
    }

    setState((prevState) => ({ ...prevState, loadingSublessons: true }));

    const payload = {
      course_id: participant.courseId,
      lms_user_id: participant.user_id,
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
            sublessons: (res.data ?? []).reduce((agg, sublesson) => {
              return {
                ...agg,
                [sublesson.sub_lessontype]: [
                  ...(agg[sublesson.sub_lessontype] ?? []),
                  sublesson,
                ],
              };
            }, {}),
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

  return (
    <>
      <div
        className="lesson-accordion"
        key={lesson.id}
        id={`accordion-${lesson.id}`}
      >
        <div className="row my-1 lesson-content">
          <div className="col-md-12 border-secondary">
            <LessonRow
              lesson={lesson}
              showOverview={() =>
                setState((prevState) => ({
                  ...prevState,
                  openOverviewModal: !prevState.openOverviewModal,
                }))
              }
              showNotes={() =>
                setState((prevState) => ({
                  ...prevState,
                  openNotesModal: !prevState.openNotesModal,
                }))
              }
              loadSublessons={toggleLessonContent}
            />
            {state.loadingSublessons ? (
              <div className="text-center">
                <Spinner />
              </div>
            ) : state.sublessons ? (
              <LessonContent
                lesson={lesson}
                sublessons={state.sublessons}
                participant={participant}
                updateSublessons={(sublessons) =>
                  setState((prevState) => ({ ...prevState, sublessons }))
                }
              />
            ) : null}
          </div>
        </div>
      </div>
      {state.openOverviewModal && (
        <Modal
          callback={() =>
            setState((prevState) => ({
              ...prevState,
              openOverviewModal: !prevState.openOverviewModal,
            }))
          }
        >
          {lesson.summary ? (
            <div className="sublesson module-content">
              <h4 className="m-0">Lesson Overview</h4>
              <div dangerouslySetInnerHTML={{ __html: lesson.summary }} />
            </div>
          ) : (
            <div className="d-flex flex-row justify-content-center jumbotron mb-2">
              <p className="mb-0">No Lesson Overview</p>
            </div>
          )}
        </Modal>
      )}
      {state.openNotesModal && (
        <Modal
          callback={() =>
            setState((prevState) => ({
              ...prevState,
              openNotesModal: !prevState.openNotesModal,
            }))
          }
        >
          <LessonNotesModalContent lesson={lesson} participant={participant} />
        </Modal>
      )}
    </>
  );
};

const LessonRow = ({ lesson, showOverview, loadSublessons, showNotes }) => {
  const [isExpanded, setExpanded] = useState(false);

  return (
    <div className="d-flex flex-row justify-content-between align-items-center">
      <div
        onClick={() => {
          setExpanded((prevState) => !prevState);
          loadSublessons();
        }}
        className="d-flex flex-row justify-content-start align-items-center accordion-icon cursor-pointer"
      >
        {
          isExpanded ? (
            <ChevronUp />
          )
          : (
            <ChevronDown />
          )
        }
        <h4 className="mt-2 mb-2">{lesson.name}</h4>
      </div>
      <div className="d-flex flex-row align-items-center">
        <p
          onClick={showOverview}
          className="text-primary my-0 mx-1 cursor-pointer"
        >
          Overview
        </p>
        <span className="text-secondary"> | </span>
        <p
          onClick={showNotes}
          className="text-primary my-0 mx-1 cursor-pointer"
        >
          Notes
        </p>
      </div>
    </div>
  );
};

const LessonContent = ({
  lesson,
  sublessons,
  participant,
  updateSublessons,
}) => {
  const [state, setState] = useState({
    selectedSublesson: undefined,
    markedSublesson: {
      sublessonId: undefined,
      loaderType: undefined,
    },
    openSublessonSidePanel: false,
  });

  const saveRemarks = async (sublesson, remark, type) => {
    if (participant.studentOrRenter) {
      return console.log("Student or Renter can't grade a sub-lesson");
    }

    if (remark === RemarksType.NOT_GRADED) {
      if (!window.confirm("Are you sure you want to reset grade?")) {
        return;
      }
    }

    const payload = {
      course_id: participant.courseId,
      sub_lesson_id: sublesson.id,
      teacher_mark: remark,
      fsm_user_id: participant.fsm_user_id,
    };

    const reqOpts = {
      method: "POST",
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    };

    setState({
      ...state,
      markedSublesson: {
        loaderType: type,
        sublessonId: sublesson.id,
      },
    });

    await fetch(`/api/course/sublesson/remarks`, reqOpts)
      .then((res) => res.json())
      .then((data) => {
        console.log(data);

        const updatedSublesson = {
          ...sublesson,
          remarks: MapRemarksType[remark],
        };

        // To make sure data should be updated locally in both
        // Sublesson side panel and complete listing of sublessons
        // On the main page

        const updatedSublessons = mergeSublessons(sublessons, updatedSublesson);

        // Update parent component
        // we could avoid this, however we need to make sure when grading
        // a sublesson other sublessons should be inactive (not clickable)
        // This to make sure moodle APIs works fine

        updateSublessons(updatedSublessons);
        // update local state
        setState((prevState) => ({
          ...prevState,
          selectedSublesson: {
            ...prevState.selectedSublesson,
            remarks: MapRemarksType[remark],
          },
          markedSublesson: {
            sublessonId: undefined,
            loaderType: undefined,
          },
        }));
      })
      .catch((error) => {
        console.log(error);
        setState((prevState) => ({
          ...prevState,
          markedSublesson: {
            sublessonId: undefined,
            loaderType: undefined,
          },
        }));
        window.alert("Something went wrong, please try again.");
      });
  };

  if (Object.keys(sublessons ?? {}).keys().length === 0) {
    return (
      <div className="ml-4">
        <h2 className="text-center">Sublessons not found</h2>
      </div>
    );
  }

  return (
    <div className="ml-4">
      {Object.entries(sublessons ?? {})
        .sort(([a], [b]) => b.length - a.length)
        .map(([type, sublessons], index) => {
          return (
            <div key={type + "-" + index} className="mx-2">
              <div className="align-items-center d-flex flex-row">
                <div className="icon border bg-dark mr-2 round-button">
                  <img
                    src={`/images/${
                      type === SubLessonTypes.FLIGHT ? "flight" : "pre-flight"
                    }.svg`}
                    height="25px"
                    width="25px"
                  />
                </div>
                <p className="mb-0 title text-uppercase">{type}</p>
              </div>
              {(sublessons ?? []).map((sublesson) => (
                <SubLessonCard
                  key={lesson.id + "-" + sublesson.id}
                  lesson={lesson}
                  sublesson={sublesson}
                  setSublesson={() =>
                    setState((prevState) => ({
                      ...prevState,
                      openSublessonSidePanel: true,
                      selectedSublesson: sublesson,
                    }))
                  }
                  selected={sublesson.id === state.selectedSublesson?.id}
                  saveRemarks={saveRemarks}
                  markedSublesson={state.markedSublesson}
                  participant={participant}
                />
              ))}
            </div>
          );
        })}
      {state.openSublessonSidePanel && state.selectedSublesson && (
        <SubLessonSidePanel
          lesson={lesson}
          sublesson={state.selectedSublesson}
          participant={participant}
          markedSublesson={state.markedSublesson}
          closePanel={() =>
            setState((prevState) => ({
              ...prevState,
              selectedSublesson: undefined,
              openSublessonSidePanel: false,
            }))
          }
          updateSublesson={(updatedSublesson) => {
            // update local component state
            setState((prevState) => ({
              ...prevState,
              selectedSublesson: updatedSublesson,
            }));

            // update parent component's state as well
            const updatedSublessons = mergeSublessons(sublessons, updatedSublesson);
            updateSublessons(updatedSublessons);
          }}
          saveRemarks={saveRemarks}
        />
      )}
    </div>
  );
};
