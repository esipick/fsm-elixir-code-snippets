import React, { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { ModuleViewActions } from "./../constants";
import { CheckCircleSolidIcon, CrossSign } from "./../common/icons";
import { RemarksButtons } from "./../common/remarks-buttons";
import { authHeaders } from "./../../utils";
import { Spinner } from "../common/spinner";
import { TakeNotes } from "./take-notes-form";
import { Modal } from "./../../common/modal";
import { PageModuleContent } from "./page-module-content";

export const SubLessonSidePanel = ({
  lesson,
  sublesson,
  participant,
  markedSublesson,
  saveRemarks,
  closePanel,
  updateSublesson,
}) => {
  const [state, setState] = useState({
    modulesContent: [],
    loadingModules: true,
    openTakeNotesModal: false,
    pageModuleUrl: undefined,
    youtubeModuleContent: undefined,
  });

  useEffect(() => {
    const fetchModules = () => {
      const payload = {
        course_id: participant.courseId,
        lms_user_id: participant.user_id,
        sub_lesson_id: sublesson.id,
      };

      const reqOpts = {
        method: "POST",
        headers: {
          ...authHeaders(),
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      };

      fetch("/api/course/sublesson/modules", reqOpts)
        .then((res) => res.json())
        .then(
          (res) => {
            setState((prevState) => ({
              ...prevState,
              modulesContent: res.data,
              loadingModules: false,
            }));
          },
          (error) => {
            console.log(error);
            setState((prevState) => ({
              ...prevState,
              loadingModules: false,
            }));
          }
        );
    };

    fetchModules();
  }, [sublesson, participant]);

  const markModuleView = (mod, action) => {
    // we already viewed the module
    if (action === ModuleViewActions.READ) {
      if (mod.completionstate && mod.vieweddate) {
        return;
      }
    }

    // only student can read the module
    if(action === ModuleViewActions.READ && !participant.studentOrRenter) {
      return;
    }

    if (action === ModuleViewActions.UNREAD) {
      if (!window.confirm("Are you sure you want to unread?")) {
        return;
      }
    }

    const moduleId = mod.id;

    let payload = {
      course_id: participant.courseId,
      module_id: moduleId,
      action,
    };

    payload = participant.studentOrRenter ? payload : {...payload, lms_user_id: participant.user_id}

    const postReqOpts = {
      method: "POST",
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    };

    // update local state to show viewed
    setState((prevState) => ({
      ...prevState,
      modulesContent: (state.modulesContent ?? []).map((mod) => {
        if (mod.id === moduleId) {
          return {
            ...mod,
            completionstate: action === ModuleViewActions.READ,
            vieweddate: Math.round(Date.now() / 1000).toString(),
          };
        }
        return mod;
      }),
    }));

    const urlPart = participant.studentOrRenter.isStudentOrRenter ? 'view' : 'unread'

    fetch(`/api/course/sublesson/${urlPart}`, postReqOpts)
      .then((res) => res.json())
      .then((data) => {
        console.log(data);
      })
      .catch((error) => {
        console.log("error", error);
      });
  };

  const toggleTakeNotesModal = () => {
    setState((prevState) => ({
      ...prevState,
      openTakeNotesModal: !prevState.openTakeNotesModal,
    }));
  };

  const togglePageModuleModal = (url) => {
    setState((prevState) => ({
      ...prevState,
      pageModuleUrl: url,
    }));
  };

  return (
    <Wrapper closePanel={closePanel}>
      <div className="row ml-0 d-flex flex-row justify-content-between align-items-center mb-2">
        <h5 className="mb-0 text-dark">{sublesson.name}</h5>
        <RemarksButtons
          {...{
            sublesson,
            markedSublesson,
            saveRemarks,
            studentOrRenter: participant.studentOrRenter,
          }}
        />
      </div>
      <div className="card-body p-0">
        {state.loadingModules ? (
          <div className="text-center">
            <Spinner />
          </div>
        ) : state.modulesContent.length === 0 ? (
          <div className="text-center">
            <p className="text-secondary">Modules Not Found</p>
          </div>
        ) : (
          state.modulesContent.map((item) => (
            <div
              key={lesson.id + "-" + sublesson.id + "-" + item.id}
              className="no-last-child-border pb-2 mb-2 border-bottom"
            >
              {(item.contents ?? []).map((content, index, originalContents) => {
                if (item.modname === "page") {
                  return (
                    <div
                      className={`d-flex flex-row align-items-center justify-content-between
                              ${
                                originalContents.length > 1
                                  ? "no-last-child-border pb-2 mb-2 border-bottom"
                                  : ""
                              }`}
                      key={
                        lesson.id + "-" + sublesson.id + "-" + item.id + index
                      }
                    >
                      <div
                        className="cursor-pointer d-flex flex-row align-items-center"
                        onClick={() => {
                          markModuleView(item, ModuleViewActions.READ);
                          togglePageModuleModal(
                            `${content.fileurl}&token=${participant.token}`
                          );
                        }}
                      >
                        <span className="mr-2">
                          <img src={item.modicon} />
                        </span>
                        <p
                          className="mb-0"
                          dangerouslySetInnerHTML={{ __html: item.name }}
                        />
                      </div>
                      {item.completionstate && item.vieweddate && (
                        <div
                          className="cursor-pointer"
                          onClick={() =>
                            markModuleView(item, ModuleViewActions.UNREAD)
                          }
                        >
                          <CheckCircleSolidIcon className={"text-success"} />
                        </div>
                      )}
                    </div>
                  );
                }

                if (content.fileurl?.includes("youtube")) {
                  return (
                    <div
                      className={`d-flex flex-row align-items-center justify-content-between
                            ${
                              originalContents.length > 1
                                ? "no-last-child-border pb-2 mb-2 border-bottom"
                                : ""
                            }`}
                      key={
                        lesson.id + "-" + sublesson.id + "-" + item.id + index
                      }
                    >
                      <div
                        className="cursor-pointer d-flex flex-row align-items-center"
                        onClick={() => {
                          markModuleView(item, ModuleViewActions.READ);
                          setState({ ...state, youtubeModuleContent: content });
                        }}
                      >
                        <span className="mr-2">
                          <img src={item.modicon} />
                        </span>
                        <p
                          className="mb-0"
                          dangerouslySetInnerHTML={{ __html: item.name }}
                        />
                      </div>
                      {item.completionstate && item.vieweddate && (
                        <div
                          className="cursor-pointer"
                          onClick={() =>
                            markModuleView(item, ModuleViewActions.UNREAD)
                          }
                        >
                          <CheckCircleSolidIcon className={"text-success"} />
                        </div>
                      )}
                    </div>
                  );
                }

                return (
                  <div
                    className={`d-flex flex-row align-items-center justify-content-between
                          ${
                            originalContents.length > 1
                              ? "no-last-child-border pb-2 mb-2 border-bottom"
                              : ""
                          }`}
                    key={lesson.id + "-" + sublesson.id + "-" + item.id + index}
                  >
                    <a
                      href={content.fileurl + "&token=" + participant.token}
                      target={"_blank"}
                      onClick={() =>
                        markModuleView(item, ModuleViewActions.READ)
                      }
                    >
                      <div className="d-flex flex-row align-items-center">
                        <span className="mr-2">
                          <img src={item.modicon} />
                        </span>
                        <p
                          className="mb-0"
                          dangerouslySetInnerHTML={{ __html: item.name }}
                        />
                      </div>
                    </a>
                    {item.completionstate && item.vieweddate && (
                      <div
                        className="cursor-pointer"
                        onClick={() =>
                          markModuleView(item, ModuleViewActions.UNREAD)
                        }
                      >
                        <CheckCircleSolidIcon className={"text-success"} />
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          ))
        )}
        <SublessonNotes
          participant={participant}
          sublesson={sublesson}
          showCreateNotesModal={toggleTakeNotesModal}
        />
        {state.openTakeNotesModal && (
          <Modal callback={toggleTakeNotesModal}>
            <TakeNotes
              sublesson={sublesson}
              participant={participant}
              closeModal={toggleTakeNotesModal}
              updateSublesson={updateSublesson}
            />
          </Modal>
        )}
        {state.pageModuleUrl && (
          <Modal callback={() => togglePageModuleModal(undefined)}>
            <PageModuleContent pageModuleUrl={state.pageModuleUrl} />
          </Modal>
        )}{" "}
        {state.youtubeModuleContent && (
          <Modal
            callback={() =>
              setState({ ...state, youtubeModuleContent: undefined })
            }
          >
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
        )}
      </div>
    </Wrapper>
  );
};

function Wrapper({ children, closePanel }) {
  return createPortal(
    <div className="sidepanel-wrapper" aria-modal={true} role="dialog">
      <div className="blur" aria-hidden={true}></div>
      <div className="sidepanel">
        <div className="text-secondary">
          <CrossSign callback={closePanel} />
          <div className="sublesson-content ml-1">{children}</div>
        </div>
      </div>
    </div>,
    document.body
  );
}

function SublessonNotes({ participant, sublesson, showCreateNotesModal }) {
  return (
    <div className="notes-section">
      {!participant.studentOrRenter && (
        <div className="d-flex flex-row align-items-center justify-content-between border-bottom">
          <h4 className="my-2">Notes</h4>
          {
            <button
              onClick={showCreateNotesModal}
              className="cursor-pointer bold text-uppercase btn btn-primary"
            >
              {sublesson.notes ? "Update Note" : "Add a Note"}
            </button>
          }
        </div>
      )}
      <div className="pt-2">
        {sublesson.notes ? (
          <div style={{ whiteSpace: "pre-line" }}> {sublesson.notes}</div>
        ) : (
          <p className="text-secondary">No notes available</p>
        )}
      </div>
    </div>
  );
}
