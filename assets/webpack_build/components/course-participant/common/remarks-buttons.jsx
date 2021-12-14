import React from "react"
import { isSatisfied, isUnsatisfied } from "../utils";
import { Spinner } from "./spinner";
import { LoaderType, RemarksType } from "../constants";

export const RemarksButtons = ({sublesson, markedSublesson, saveRemarks, studentOrRenter}) => {
  
    const satisfied = isSatisfied(sublesson.remarks);
    const unsatisfied = isUnsatisfied(sublesson.remarks);
  
    // if lesson is not graded and view is for student or renter
    // don't show grade status
    if(!(satisfied || unsatisfied) && studentOrRenter) {
      return null
    }
  
    if(studentOrRenter) {
        if (satisfied) {
          return (
              <div className={"text-success text-uppercase"}>Sat</div>
          )
        }
        return (
          <div className={"text-danger text-uppercase"}>Unsat</div>
        )
    }
  
    return (
      <div className="d-flex flex-row align-items-center text-uppercase">
      {markedSublesson.loaderType === LoaderType.SATISFACTORY &&
      markedSublesson.sublessonId === sublesson.id ? (
        <Spinner />
      ) : (
        <div
          className={`button-remark ${ satisfied  ? "text-success" : "text-secondary" }`}
          onClick={() => {
            satisfied ? 
            saveRemarks(
              sublesson,
              RemarksType.NOT_GRADED,
              LoaderType.SATISFACTORY
            )
            :
            saveRemarks(
              sublesson,
              RemarksType.SATISFACTORY,
              LoaderType.SATISFACTORY
            )
          }}
        >
          Sat
        </div>
      )}
      <span className="text-secondary"> | </span>
      {markedSublesson.loaderType === LoaderType.UNSATISFACTORY &&
      markedSublesson.sublessonId === sublesson.id ? (
        <Spinner />
      ) : (
        <div
          className={`button-remark ${ unsatisfied ? "text-danger" : "text-secondary" }`}
          onClick={() => {
            unsatisfied ? 
            saveRemarks(
              sublesson,
              RemarksType.NOT_GRADED,
              LoaderType.UNSATISFACTORY
            )
            :
            saveRemarks(
              sublesson,
              RemarksType.UNSATISFACTORY,
              LoaderType.UNSATISFACTORY
            )
          }}
        >
          Unsat
        </div>
      )}
  
    </div>
     )
  }