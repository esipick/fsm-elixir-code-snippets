import React, { useState } from "react";
import { Modal } from "../common/modal";
import { authHeaders } from "../utils";

const LoaderType = {
  SATISFACTORY: 1,
  UNSATISFACTORY: 2,
  NOTES: 3,
  SUB_LESSON_CONTENT: 4,
  PAGE_MODULE_CONTENT: 5
};

const RemarksType = {
  SATISFACTORY: 1,
  UNSATISFACTORY: 2
};

const CourseLessons = ({ participantCourse, courseId }) => {
  const [state, setState] = useState({
    lessonId: undefined,
    subLessonId: undefined,
    loaderType: undefined, // LoaderType
    participant: participantCourse,
    summaryModal: false,
    subLessonPanel: false,
    subLesson: undefined
  });

  const saveRemarks = async (subLessonId, remark, type) => {
    const payload = {
      course_id: courseId,
      sub_lesson_id: subLessonId,
      teacher_mark: remark,
      fsm_user_id: state.participant.fsm_user_id,
      notes: null
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
      subLessonId: subLessonId
    });

    await fetch(`/api/course/sublesson/remarks`, reqOpts)
      .then((res) => res.json())
      .then((data) => {
        updateParticipant(state.lessonId, subLessonId, data.participantCourse)
      })
      .catch((error) => {
        console.log(error);
        setState({
          ...state,
          loaderType: undefined,
          subLessonId: undefined
        });
        window.alert("Something went wrong, please try again.");
      });
  };

  const handleCloseModal = () => {
    setState({
      ...state,
      subLessonId: undefined,
      lessonId: undefined,
      summaryModal: false
    });
  };

  const handleCloseSidebarPanel = () => {
    setState({
      ...state,
      subLessonPanel: false,
      subLesson: undefined,
      lessonId: undefined
    });
  };

  const updateParticipant = (lessonId, subLessonId, participant) => {
    
    let subLesson = undefined

    if(state.subLessonPanel) {
      subLesson = (participant.lessons ?? [])
      .find(l => l.id === lessonId)?.sub_lessons?.find(sl => sl.id === subLessonId)
    }

    setState({
      ...state,
      loaderType: undefined,
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
                lessonId={state.lessonId}
                subLesson={state.subLesson}
                participant={{...state.participant, courseId}}
                markedSubLesson={{
                  loaderType: state.loaderType,
                  subLessonId: state.subLessonId,
                }}
                saveRemarks={saveRemarks}
                setParticipant={updateParticipant}
              />
            </div>
          </div>
        )}
        {(state.participant.lessons ?? []).map((lesson) => (
          <div key={lesson.id} id={`accordion-${lesson.id}`}>
            <div className="row my-1 lesson-content">
              <div className="col-md-12 border-secondary">
                <div className="d-flex flex-row justify-content-between align-items-center">
                  <h3 className="mb-2">{lesson.name}</h3>
                  <a
                    href="#"
                    onClick={() =>
                      setState({
                        ...state,
                        summaryModal: true,
                        lessonId: lesson.id,
                      })
                    }
                    className="text-primary"
                  >
                    View Summary
                  </a>
                </div>
                {(lesson.sub_lessons ?? []).map((subLesson) => (
                  <SubLessonCard
                    key={lesson.id + "-" + subLesson.id}
                    lessonId={lesson.id}
                    subLesson={subLesson}
                    markedSubLesson={{
                      loaderType: state.loaderType,
                      subLessonId: state.subLessonId,
                    }}
                    saveRemarks={saveRemarks}
                    showSubLesson={() =>
                      setState({
                        ...state,
                        lessonId: lesson.id,
                        subLessonPanel: true,
                        subLesson: subLesson,
                      })
                    }
                  />
                ))}
              </div>
            </div>
            {state.summaryModal && state.lessonId === lesson.id && (
              <Modal callback={handleCloseModal}>
               {
                 lesson.summary ? (
                    <div className="sublesson module-content">
                      <div dangerouslySetInnerHTML={{ __html: lesson.summary }} />
                    </div>
                  )
                : (
                  <div className="d-flex flex-row justify-content-center jumbotron mb-2">
                    <p className="mb-0">No Summary</p>
                  </div>
                )
               }
              </Modal>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

const SubLessonCard = ({
  lessonId,
  subLesson,
  markedSubLesson,
  saveRemarks,
  showSubLesson
}) => {
  const satisfied = isSatisfied(subLesson.remarks);
  const unsatisfied = isUnsatisfied(subLesson.remarks);

  return (
    <div className="row mx-2 1d-flex flex-row justify-content-between no-last-child-border border-bottom">
      <div
        className="accordion-icon d-flex flex-row justify-content-start align-items-center"
        id={`heading${lessonId}-${subLesson.id}`}
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

      <div className="d-flex flex-row align-items-center text-uppercase my-2">
        {markedSubLesson.loaderType === LoaderType.SATISFACTORY &&
        markedSubLesson.subLessonId === subLesson.id ? (
          <Spinner />
        ) : (
          <div
            className={`button-remark text-secondary ${
              satisfied ? "active disabled-click" : ""
            }`}
            disabled={satisfied}
            onClick={() =>
              saveRemarks(
                subLesson.id,
                RemarksType.SATISFACTORY,
                LoaderType.SATISFACTORY
              )
            }
          >
            Satisfactory
          </div>
        )}
        <span className="text-secondary"> | </span>
        {markedSubLesson.loaderType === LoaderType.UNSATISFACTORY &&
        markedSubLesson.subLessonId === subLesson.id ? (
          <Spinner />
        ) : (
          <div
            className={`button-remark text-secondary ${
              unsatisfied ? "active disabled-click" : ""
            }`}
            disabled={unsatisfied}
            onClick={() =>
              saveRemarks(
                subLesson.id,
                RemarksType.UNSATISFACTORY,
                LoaderType.UNSATISFACTORY
              )
            }
          >
            Unsatisfactory
          </div>
        )}
      </div>
    </div>
  );
};

const SubLessonPanelContent = ({
  lessonId,
  subLesson,
  participant,
  setParticipant,
  markedSubLesson,
  saveRemarks
}) => {

  const [state, setState] = useState({
    youtubeModuleContent: undefined,
    takeNotesModal: false,
    pageModuleContentModal: false,
    pageModuleContent: undefined,
    loaderType: undefined,
    error: undefined
  });

  const getModulePageContent = (url) => {
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

  const satisfied = isSatisfied(subLesson.remarks);
  const unsatisfied = isUnsatisfied(subLesson.remarks);

  return (
    <div className="sublesson-content ml-1">
      <div className="row ml-0 d-flex flex-row justify-content-between align-items-center mb-2">
        <h5 className="mb-0 text-dark">{subLesson.name}</h5>
        <div className="h5 mb-0 d-flex flex-row align-items-center text-uppercase">
          {markedSubLesson.loaderType === LoaderType.SATISFACTORY &&
          markedSubLesson.subLessonId === subLesson.id ? (
            <Spinner />
          ) : (
            <div
              className={`button-remark text-secondary ${
                satisfied ? "active disabled-click" : ""
              }`}
              disabled={satisfied}
              onClick={() =>
                saveRemarks(
                  subLesson.id,
                  RemarksType.SATISFACTORY,
                  LoaderType.SATISFACTORY
                )
              }
            >
              Satisfactory
            </div>
          )}
          <span className="text-secondary"> | </span>
          {markedSubLesson.loaderType === LoaderType.UNSATISFACTORY &&
          markedSubLesson.subLessonId === subLesson.id ? (
            <Spinner />
          ) : (
            <div
              className={`button-remark text-secondary ${
                unsatisfied ? "active disabled-click" : ""
              }`}
              disabled={unsatisfied}
              onClick={() =>
                saveRemarks(
                  subLesson.id,
                  RemarksType.UNSATISFACTORY,
                  LoaderType.UNSATISFACTORY
                )
              }
            >
              Unsatisfactory
            </div>
          )}
        </div>
      </div>
      <div className="card-body p-0">
        {(subLesson.modules ?? []).map((module) => (
          <div
            key={lessonId + "-" + subLesson.id + "-" + module.id}
            className="no-last-child-border pb-2 mb-2 border-bottom d-flex flex-row align-items-center"
          >
            <span className="mr-2">
              <img src={module.modicon} />
            </span>
            {(module.contents ?? []).map((content, index) => {
              if (module.modname === "page") {
                return (
                  <div
                    className="cursor-pointer"
                    key={ lessonId + "-" + subLesson.id + "-" + module.id + index }
                    onClick={() =>
                      getModulePageContent(`${content.fileurl}&token=${participant.token}`)
                    }
                  >
                    <p className="mb-0" dangerouslySetInnerHTML={{ __html: module.name }} />
                  </div>
                );
              }

              if(content.fileurl?.includes("youtube")) {
                return (
                  <div
                    className="cursor-pointer"
                    key={
                      lessonId + "-" + subLesson.id + "-" + module.id + index
                    }
                    onClick={() => setState({...state, youtubeModuleContent: content})}
                  >
                    <p className="mb-0" dangerouslySetInnerHTML={{ __html: module.name }} />
                  </div>
                );
              }

              return (
                <a
                  key={lessonId + "-" + subLesson.id + "-" + module.id + index}
                  href={content.fileurl + "&token=" + participant.token}
                  target={"_blank"}
                >
                   <p className="mb-0" dangerouslySetInnerHTML={{ __html: module.name }} />
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
                  setParticipant(lessonId, subLesson.id, participant)
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
          <div
            onClick={() => setState({...state, takeNotesModal: true})}
            className="cursor-pointer bold text-uppercase btn btn-primary"
          >
            Add a Note
          </div>
        </div>
        <div className="pt-2">
         {
           subLesson.notes ? 
           <p>{subLesson.notes}</p>
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
      course_id: courseId,
      sub_lesson_id: subLesson.id,
      teacher_mark: null,
      fsm_user_id: participant.fsm_user_id,
      notes: state.notes,
    };

    const reqOpts = {
      method: "POST",
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json",
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

const ChevronRight = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="text-secondary chevron-right text-primary"
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

const Spinner = ({ borderColor }) => (
  <div className="lds-ring">
    <div style={{borderColor}}></div>
    <div></div>
    <div></div>
    <div></div>
  </div>
);

export default CourseLessons;
