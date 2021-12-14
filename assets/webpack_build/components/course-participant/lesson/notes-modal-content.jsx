import React, { useState, useEffect } from "react";
import { Spinner } from "./../common/spinner";
import { authHeaders } from "./../../utils";

export const LessonNotesModalContent = ({ lesson, participant }) => {  
    const [state, setState] = useState({
      sublessons: [],
      loadingSublessons: true
    })
  
    useEffect(() => {
      const fetchSublessons = () => {
  
        const payload = {
          course_id: participant.courseId,
          lms_user_id: participant.fsm_user_id,
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
      }

      fetchSublessons();
    }, [lesson, participant]);

    if(state.loadingSublessons) {
        return (
            <div className="sublesson">
                <h4 className="m-0">Lesson Notes</h4>
                <div className="text-center my-2">
                    <Spinner />
                </div>
            </div>
        );
    };

    if(state.sublessons.length === 0) {
        return (
            <div className="sublesson">
                <h4 className="m-0">Lesson Notes</h4>
                <p className="my-2 text-center text-secondary">Not Found</p>
            </div>
        )
    };

    return (
        <div className="sublesson module-content">
            <h4 className="m-0">Lesson Notes</h4>
            <div>
            {
                (state.sublessons).map(sl => {
                    if(!sl.notes) {
                        return null
                    };

                    return (
                        <div key={lesson.id + "-" + sl.id} className="p-1">
                            <p className="bold m-0">{sl.name}</p>
                            <div style={{whiteSpace: "pre-line"}}> {sl.notes}</div>
                        </div>
                    );
                })
            }
            </div>
        </div>
    );

  }
  