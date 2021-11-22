import React, { useState } from "react";
import { Modal } from "../common/modal";
import { authHeaders } from "../utils";

const LoaderType = {
  NOT_GRADED: 0,
  SATISFACTORY: 1,
  UNSATISFACTORY: 2,
  NOTES: 3,
  SUB_LESSON_CONTENT: 4,
  PAGE_MODULE_CONTENT: 5
};

const RemarksType = {
  NOT_GRADED: 0,
  SATISFACTORY: 1,
  UNSATISFACTORY: 2
};

const CourseLessons = ({ participantCourse, userRoles, courseId }) => {
  const [state, setState] = useState({
    lesson: undefined,
    loaderType: undefined, // LoaderType
    participant: participantCourse,
    lessonOverviewModal: false,
    subLessonPanel: false,
    subLesson: undefined,
    lessonNotesModal: false
  });

  const saveRemarks = async (subLesson, remark, type) => {
    const payload = {
      course_id: parseInt(courseId),
      sub_lesson_id: subLesson.id,
      teacher_mark: remark,
      fsm_user_id: state.participant.fsm_user_id
    };

    const reqOpts = {
      method: "POST",
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    };

    setState({
      ...state,
      loaderType: type,
      subLesson
    });

    await fetch(`/api/course/sublesson/remarks`, reqOpts)
      .then((res) => res.json())
      .then((data) => {
        updateParticipant(state.lesson, subLesson.id, data.participantCourse)
      })
      .catch((error) => {
        console.log(error);
        setState({
          ...state,
          loaderType: undefined,
          subLesson: undefined
        });
        window.alert("Something went wrong, please try again.");
      });
  };

  const handleCloseModal = () => {
    setState({
      ...state,
      subLesson: undefined,
      lesson: undefined,
      lessonOverviewModal: false,
      lessonNotesModal: false
    });
  };

  const handleCloseSidebarPanel = () => {
    setState({
      ...state,
      subLessonPanel: false,
      subLesson: undefined,
      lesson: undefined
    });
  };

  const updateParticipant = (lesson, subLessonId, participant) => {
    
    let subLesson = undefined

    if(state.subLessonPanel) {
      subLesson = (participant.lessons ?? [])
      .find(l => l.id === lesson.id)?.sub_lessons?.find(sl => sl.id === subLessonId)
    }

    setState({
      ...state,
      loaderType: undefined,
      lesson,
      participant,
      subLesson
    });
  }

  return (
    <div className="card">
      <div className="card-header d-flex flex-column">
        {state.subLessonPanel && state.subLesson && (
          <div className="sidepanel">
            <div className="text-secondary">
              <CrossSign callback={handleCloseSidebarPanel} />
              <SubLessonPanelContent
                lesson={state.lesson}
                subLesson={state.subLesson}
                participant={{...state.participant, courseId}}
                markedSubLesson={{
                  loaderType: state.loaderType,
                  subLessonId: state.subLesson.id,
                }}
                saveRemarks={saveRemarks}
                setParticipant={updateParticipant}
                userRoles={userRoles}
              />
            </div>
          </div>
        )}
        {
          (state.participant.lessons ?? []).length === 0 && (
            <div className="row my-1 lesson-content">
              <div className="col-md-12 border-secondary">
                  <h4 className="row justify-content-center text-secondary mt-0">Lessons Not Found</h4>
              </div>
            </div>
          )
        }
        {(state.participant.lessons ?? []).map((lesson, index) => (
          <div className="lesson-accordion" key={lesson.id} id={`accordion-${lesson.id}`}>
            <div className="row my-1 lesson-content">
              <div className="col-md-12 border-secondary">
                <div className="d-flex flex-row justify-content-between align-items-center">
                  <div className="d-flex flex-row justify-content-start align-items-center accordion-icon cursor-pointer"
                    data-toggle="collapse"
                    data-target={"#collapse-"+lesson.id} 
                    aria-expanded={index === 0}
                    aria-controls={"collapse-"+lesson.id}
                    >
                      <ChevronDown />
                      <h4 className="mt-2 mb-2">{lesson.name}</h4>
                  </div>
                 <div className="d-flex flex-row align-items-center">
                  <p
                      onClick={() =>
                        setState({
                          ...state,
                          lesson,
                          lessonOverviewModal: true
                        })
                      }
                      className="text-primary my-0 mx-1 cursor-pointer"
                    >
                      Overview
                    </p>
                    <span className="text-secondary"> | </span>
                    <p
                      onClick={() =>
                        setState({
                          ...state,
                          lesson,
                          lessonNotesModal: true
                        })
                      }
                      className="text-primary my-0 mx-1 cursor-pointer"
                    >
                      Notes
                    </p>
                  </div>
              </div>
                <div id={"collapse-"+lesson.id} className={`accordion-collapse collapse ${index === 0 ? 'show' : ''}`} 
                  aria-labelledby={"heading-"+lesson.id} 
                  data-parent={"#accordion-"+lesson.id}
                  >
                    {(lesson.sub_lessons ?? []).map((subLesson) => (
                      <SubLessonCard
                        key={lesson.id + "-" + subLesson.id}
                        lesson={lesson}
                        subLesson={subLesson}
                        selectedSubLesson={state.subLesson}
                        markedSubLesson={{
                          loaderType: state.loaderType,
                          subLessonId: state.subLesson?.id,
                        }}
                        saveRemarks={saveRemarks}
                        showSubLesson={() =>
                          setState({
                            ...state,
                            lesson: lesson,
                            subLessonPanel: true,
                            subLesson: subLesson,
                          })
                        }
                      />
                    ))}
                </div>
              </div>
            </div>
          </div>
        ))}
        {state.lessonOverviewModal && state.lesson && (
              <Modal callback={handleCloseModal}>
               {
                 state.lesson.summary ? (
                    <div className="sublesson module-content">
                      <h4 className="m-0">Lesson Overview</h4>
                      <div dangerouslySetInnerHTML={{ __html: state.lesson.summary }} />
                    </div>
                  )
                : (
                  <div className="d-flex flex-row justify-content-center jumbotron mb-2">
                    <p className="mb-0">No Lesson Overview</p>
                  </div>
                )
               }
              </Modal>
            )}
            {state.lessonNotesModal && state.lesson && (
              <Modal callback={handleCloseModal}>
               {
                <div className="sublesson module-content">
                  <h4 className="m-0">Lesson Notes</h4>
                  <div>
                  {
                    (state.lesson.sub_lessons ?? []).map(sl => {
                        if(!sl.notes) {
                          return null
                        }
                        return (<div key={state.lesson.id + "-" + sl.id} className="border p-1 rounded mb-1">
                          <p className="bold border-bottom m-0">{sl.name}</p>
                          <textarea className="w-100 text-secondary border-0" readOnly={true} rows={2} value={sl.notes}/>
                        </div>)
                    })
                  }
                  </div>
                </div>
               }
              </Modal>
            )}
      </div>
    </div>
  );
};

const SubLessonCard = ({
  lesson,
  subLesson,
  selectedSubLesson,
  markedSubLesson,
  saveRemarks,
  showSubLesson
}) => {
  
  return (
    <div className={`row py-2 mx-2 d-flex flex-row justify-content-between no-last-child-border border-bottom ${selectedSubLesson?.id === subLesson.id ? 'bg-light' : ''}`}>
      <div
        className="d-flex flex-row justify-content-start align-items-center"
        id={`heading${lesson.id}-${subLesson.id}`}
      >
        <a
          onClick={showSubLesson}
          className="cursor-pointer d-flex flex-row justify-content-start align-items-center">
          <ChevronRight />
          <h5 className="mb-0 text-dark">
            {subLesson.name}
          </h5>
        </a>
      </div>
      <RemarkButtons {...{markedSubLesson, saveRemarks, subLesson}}  />
    </div>
  );
};

const RemarkButtons = ({subLesson, markedSubLesson, saveRemarks}) => {
  
  const satisfied = isSatisfied(subLesson.remarks);
  const unsatisfied = isUnsatisfied(subLesson.remarks);

   return (
    <div className="d-flex flex-row align-items-center text-uppercase">
    {markedSubLesson.loaderType === LoaderType.SATISFACTORY &&
    markedSubLesson.subLessonId === subLesson.id ? (
      <Spinner />
    ) : (
      <div
        className={`button-remark ${
          satisfied ? "text-success disabled-click" : "text-secondary"
        }`}
        disabled={satisfied}
        onClick={() =>
          saveRemarks(
            subLesson,
            RemarksType.SATISFACTORY,
            LoaderType.SATISFACTORY
          )
        }
      >
        Sat
      </div>
    )}
    <span className="text-secondary"> | </span>
    {markedSubLesson.loaderType === LoaderType.UNSATISFACTORY &&
    markedSubLesson.subLessonId === subLesson.id ? (
      <Spinner />
    ) : (
      <div
        className={`button-remark ${
          unsatisfied ? "text-danger disabled-click" : "text-secondary"
        }`}
        disabled={unsatisfied}
        onClick={() =>
          saveRemarks(
            subLesson,
            RemarksType.UNSATISFACTORY,
            LoaderType.UNSATISFACTORY
          )
        }
      >
        Unsat
      </div>
    )}

    <span className="text-secondary"> | </span>
    {markedSubLesson.loaderType === LoaderType.NOT_GRADED &&
    markedSubLesson.subLessonId === subLesson.id ? (
      <Spinner />
    ) : (
      <button
        id="btn-reset-grading"
        rel="popover"
        data-placement="bottom"
        data-original-title="Reset Grading"
        disabled={!(satisfied || unsatisfied)}
        className={`btn btn-sm p-1 m-0 ml-1 ${satisfied || unsatisfied ? 'btn-danger' : 'btn-light'}`}
        onClick={() =>
          saveRemarks(
            subLesson,
            RemarksType.NOT_GRADED,
            LoaderType.NOT_GRADED
          )
        }
      >
        Reset
      </button>
    )}
  </div>
   )
}

const SubLessonPanelContent = ({
  lesson,
  subLesson,
  participant,
  setParticipant,
  markedSubLesson,
  saveRemarks,
  userRoles
}) => {

  const [state, setState] = useState({
    youtubeModuleContent: undefined,
    takeNotesModal: false,
    pageModuleContentModal: false,
    pageModuleContent: undefined,
    loaderType: undefined,
    error: undefined
  });

  const getModulePageContent = (moduleId, url) => {
    const reqOpts = {
      method: "GET"
    };

    setState({
      ...state,
      pageModuleContentModal: true,
      loaderType: LoaderType.PAGE_MODULE_CONTENT
    })

   fetch(url, reqOpts)
      .then((res) => res.text())
      .then((data) => {
        setState({
          ...state,
          loaderType: undefined,
          pageModuleContentModal: true,
          pageModuleContent: data
        });
      })
      .catch((error) => {
        console.log(error)
        setState({
          ...state,
          loaderType: undefined,
          pageModuleContentModal: true,
          error: "Something went wrong. Please close this and try again."
        });
      });
  };

  const markModuleView = (mod) => {

    // we already viewed the module
    if(mod.completionstate && mod.vieweddate) {
      return
    }

    // only student can mark module as viewed
    if(!isStudent(userRoles)) {
      return
    }

    const payload = {
      course_id: parseInt(participant.courseId),
      module_id: mod.id
    };

    const postReqOpts = {
      method: "POST",
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    };

    fetch(`/api/course/sublesson/module/view`, postReqOpts)
      .then((res) => res.json())
      .then((data) => {
        console.log(data)
        const updatedLesson = {
          ...lesson,
          sub_lessons: (lesson.sub_lessons ?? []).map(sl => {
            return {
              ...sl,
              modules: (sl.modules ?? []).map(mod => {
                if(mod.id === moduleId) {
                  return {
                    ...mod,
                    completionstate: true,
                    vieweddate: Math.round(Date.now()/1000).toString()
                  }
                }
                return mod
              })
            }
          })
        }

        const updatedParticipant = {
          ...participant,
          lessons: participant.lessons.map(l => {
            if(l.id === updatedLesson.id) {
              return updatedLesson
            }
            return l
          })
        }

        // update parent state
        setParticipant(updatedLesson, subLesson.id, updatedParticipant)
      })
      .catch((error) => {
        console.log("error", error);
    });
  }

  return (
    <div className="sublesson-content ml-1">
      <div className="row ml-0 d-flex flex-row justify-content-between align-items-center mb-2">
        <h5 className="mb-0 text-dark">{subLesson.name}</h5>
        <RemarkButtons {...{subLesson, markedSubLesson, saveRemarks}} />
      </div>
      <div className="card-body p-0">
        {(subLesson.modules ?? []).map((mod) => (
          <div
            key={lesson.id + "-" + subLesson.id + "-" + mod.id}
            className="no-last-child-border pb-2 mb-2 border-bottom"
          >
            {(mod.contents ?? []).map((content, index, originalContents) => {
              if (mod.modname === "page") {
                return (
                  <div
                    className={`cursor-pointer d-flex flex-row align-items-center justify-content-between
                      ${originalContents.length > 1 ? 'no-last-child-border pb-2 mb-2 border-bottom' : ''}`}
                    key={ lesson.id + "-" + subLesson.id + "-" + mod.id + index }
                    onClick={() => {
                        markModuleView(mod);
                        getModulePageContent(mod.id, `${content.fileurl}&token=${participant.token}`);
                      }
                    }
                  >
                    <div className="d-flex flex-row align-items-center">
                      <span className="mr-2">
                        <img src={mod.modicon} />
                      </span>
                      <p className="mb-0" dangerouslySetInnerHTML={{ __html: mod.name }} />
                    </div>
                    {
                      (mod.completionstate && mod.vieweddate) && (
                        <CheckCircleIcon className={"text-success"} />
                      )
                    }
                  </div>
                );
              }

              if(content.fileurl?.includes("youtube")) {
                return (
                  <div
                    className={`cursor-pointer d-flex flex-row align-items-center justify-content-between
                    ${originalContents.length > 1 ? 'no-last-child-border pb-2 mb-2 border-bottom' : ''}`}
                    key={
                      lesson.id + "-" + subLesson.id + "-" + mod.id + index
                    }
                    onClick={() => {
                      markModuleView(mod);
                      setState({...state, youtubeModuleContent: content});
                    }}
                  >
                    <div className="d-flex flex-row align-items-center">
                      <span className="mr-2">
                          <img src={mod.modicon} />
                        </span>
                        <p className="mb-0" dangerouslySetInnerHTML={{ __html: mod.name }} />
                    </div>
                    {
                      (mod.completionstate && mod.vieweddate) && (
                        <CheckCircleIcon className={"text-success"} />
                      )
                    }
                  </div>
                );
              }

              return (
                <a
                  className={`cursor-pointer d-flex flex-row align-items-center justify-content-between
                  ${originalContents.length > 1 ? 'no-last-child-border pb-2 mb-2 border-bottom' : ''}`}
                  key={lesson.id + "-" + subLesson.id + "-" + mod.id + index}
                  href={content.fileurl + "&token=" + participant.token}
                  target={"_blank"}
                  onClick={() => markModuleView(mod)}
                >
                    <div className="d-flex flex-row align-items-center">
                      <span className="mr-2">
                        <img src={mod.modicon} />
                      </span>
                      <p className="mb-0" dangerouslySetInnerHTML={{ __html: mod.name }} />
                    </div>
                    {
                      (mod.completionstate && mod.vieweddate) && (
                        <CheckCircleIcon className={"text-success"} />
                      )
                    }
                </a>
              );
            })}
          </div>
        ))}
      </div>
      {(state.pageModuleContentModal) && (
        <Modal callback={() => setState({
          ...state,
          pageModuleContentModal: false,
          pageModuleContent: undefined,
          loaderType: undefined,
          error: undefined
        })}>
          {
            (state.loaderType === LoaderType.PAGE_MODULE_CONTENT) &&  (
              <div className="d-flex flex-column mb-2 justify-content-cente align-items-center jumbotron">
                <Spinner />
                <p className="mb-0">Loading...</p>
              </div>
            )
          }
          {
            state.pageModuleContent && (
                <div
                  className="sublesson module-content"
                  dangerouslySetInnerHTML={{ __html: state.pageModuleContent }}
                />
            )
          }
          {
            state.error && (
              <div className="d-flex flex-row justify-content-center jumbotron mb-2">
                <p>{state.error}</p>
              </div>
            )
          }
        </Modal>
      )}
      {
        state.youtubeModuleContent && (
          <Modal callback={() => setState({...state, youtubeModuleContent: undefined})}>
            <div className="w-100">
              <p className="bold">{state.youtubeModuleContent.filename}</p>
              <iframe
                  src={`${state.youtubeModuleContent.fileurl}?rel=0`}
                  className="w-100"
                  height={320}
                  frameBorder="0"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope;"
                  allowFullScreen
                  title={state.youtubeModuleContent.filename}
                />
            </div>
          </Modal>
        )
      }
      {
        state.takeNotesModal && (
          <Modal callback={() => setState({...state, takeNotesModal: false})}>
            <TakeNotes
              closeModal={() => setState({...state, takeNotesModal: false})}
              courseId={participant.courseId}
              participant={participant}
              subLesson={subLesson}
              setParticipant={  
                (participant) => {
                  setParticipant(lesson, subLesson.id, participant)
                  setState({...state, takeNotesModal: false})
                }
              }
            />
          </Modal>
        )
      }
      <div className="notes-section">
        <div className="d-flex flex-row align-items-center justify-content-between border-bottom">
          <h4 className="my-2">Notes</h4>
          {
            !isStudent(userRoles) && (
                <button
                onClick={() => setState({...state, takeNotesModal: true})}
                className="cursor-pointer bold text-uppercase btn btn-primary"
              >
                Add a Note
              </button>
            )
          }
        </div>
        <div className="pt-2">
         {
           subLesson.notes ? 
           <textarea className="w-100 border-0" readOnly={true} rows={5} value={subLesson.notes}/>
           :
           <p className="text-secondary">No notes available</p>
         }
        </div>
      </div>
    </div>
  );
};

const TakeNotes = ({
  closeModal,
  subLesson,
  courseId,
  participant,
  setParticipant
}) => {

  const [state, setState] = useState({
    notes: subLesson.notes ?? "",
    submitting: false,
    error: undefined
  });

  const handleFormSubmission = (event) => {
    event.preventDefault();

    const payload = {
      course_id: parseInt(courseId),
      sub_lesson_id: subLesson.id,
      fsm_user_id: participant.fsm_user_id,
      notes: state.notes
    };

    const reqOpts = {
      method: "POST",
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    };

    setState({
      ...state,
      submitting: true
    });

    fetch(`/api/course/sublesson/remarks`, reqOpts)
      .then((res) => res.json())
      .then((data) => {    
        setParticipant(data.participantCourse)
      })
      .catch((error) => {
        console.log(error);
        setState({
          ...state,
          error: "Something went wrong, please try again."
        });

        setTimeout(() => {
          setState({ ...state, error: undefined });
        }, 3000);
      });
  };

  return (
    <div className="block">
      <p className="bold text-uppercase">Add Notes</p>
      <form onSubmit={handleFormSubmission}>
        <textarea
          required
          className="w-100 p-2"
          aria-label="With textarea"
          rows={5}
          required={true}
          onChange={(event) =>
            setState({ ...state, notes: event.target.value })
          }
          value={state.notes}
          placeholder="Write here"
        >
          {state.notes}
        </textarea>
        {state.error && <p className="text-danger">{state.error}</p>}
        {
          <button
            type="submit"
            disabled={state.submitting || !state.notes}
            className={`w-100 btn d-inline-flex align-items-center ${
              state.submitting ? "pt-1 btn-secondary" : "btn-primary"
            }`}
          >
            {state.submitting ? (
              <>
                <Spinner borderColor={"white"} />
                <span className="mx-auto mt-2">Saving...</span>
              </>
            ) : (
              <span className="mx-auto">Save</span>
            )}
          </button>
        }
      </form>
      <button
        disabled={state.submitting}
        className="w-100 btn btn-secondary text-dark"
        onClick={closeModal}
      >
        Cancel
      </button>
    </div>
  );
};

const isSatisfied = (remarks) => remarks === "satisfactory";
const isUnsatisfied = (remarks) => remarks === "not_satisfactory";
const isStudent = (roles) => roles.length === 1 && roles.includes("student");

const ChevronRight = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="chevron-right text-primary"
    fill="currentColor"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      fillRule="evenodd"
      d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
      clipRule="evenodd"
    />
  </svg>
);

const ChevronDown = () => (
  <svg xmlns="http://www.w3.org/2000/svg"
      className="chevron-down mr-2 text-primary"
      fill="currentColor"
      viewBox="0 0 24 24" 
      stroke="currentColor"
    >
    <path 
      fillRule="evenodd"
      d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
      clipRule="evenodd" 
    />
  </svg>
)

const CrossSign = ({ callback }) => (
  <svg
    onClick={callback}
    xmlns="http://www.w3.org/2000/svg"
    className="btn-close cursor-pointer"
    viewBox="0 0 20 20"
    fill="currentColor"
  >
    <path
      fillRule="evenodd"
      d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
      clipRule="evenodd"
    />
  </svg>
);

const CheckCircleIcon = ({ className }) => (
  <svg xmlns="http://www.w3.org/2000/svg" className={className} fill="none" height="24" width="24" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
  </svg>
)

const Spinner = ({ borderColor }) => (
  <div className="lds-ring">
    <div style={{borderColor}}></div>
    <div></div>
    <div></div>
    <div></div>
  </div>
);

export default CourseLessons;
