import React, { useState } from "react";
import { Spinner } from "../common/spinner";
import { authHeaders } from "./../../utils";

export const TakeNotes = ({
  closeModal,
  sublesson,
  participant,
  updateSublesson,
}) => {
  const [state, setState] = useState({
    notes: sublesson.notes ?? "",
    submitting: false,
    error: undefined,
  });

  const handleFormSubmission = (event) => {
    event.preventDefault();

    const payload = {
      course_id: participant.courseId,
      sub_lesson_id: sublesson.id,
      fsm_user_id: participant.fsm_user_id,
      notes: state.notes,
    };

    const reqOpts = {
      method: "POST",
      headers: {
        ...authHeaders(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    };

    setState((prevState) => ({
      ...prevState,
      submitting: true
    }));

    fetch(`/api/course/sublesson/notes`, reqOpts)
      .then((res) => res.json())
      .then((data) => {
        console.log(data);
        // update local component state
        setState((prevState) => ({
          ...prevState,
          submitting: false
        }));
        // update parent and grandparent component state
        updateSublesson({ ...sublesson, notes: state.notes });
      })
      .catch((error) => {
        console.log(error);
        setState({
          ...state,
          error: "Something went wrong, please try again.",
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
          autoFocus={!state.notes}
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
