import React, { useState } from 'react';

const CourseLessons = ({ userCourse, currentUser, courseId, userId }) => {
    const [course, setCourse] = useState(userCourse)

    console.log(course)

    const handleRemarks = (sublessonId) => {}
    roomroom
    return (<div className="card">
            <div className="card-header d-flex flex-column">
                {
                    course.lessons.map(lesson => <LessonCard key={lesson.id} lesson={lesson} setRemarks={handleRemarks} />)
                }
            </div>
      </div>
    )
}

const LessonCard = ({ lesson, setRemarks }) => {
    return (
        <div id={`accordion-${lesson.id}`}>
            <div className="row my-2">
                <div className="col-md-12 border-secondary border-bottom">
                    <h3>{lesson.name} <span className="text-primary h-5"> </span></h3>
                    {
                        lesson.sub_lessons.map(subLesson => <SubLessonCard
                            key={lesson.id +"-"+ subLesson.id}
                            lessonId={lesson.id}
                            subLesson={subLesson} />
                        )
                    }
                </div>
            </div>
        </div>
    )
}

const SubLessonCard = ({lessonId, subLesson}) => {
    return (
        <div className="border-secondary border-bottom">
            <div className="py-4 mx-3">
                <div className="row ml-0 d-flex flex-row justify-content-between">
                    <div className="row accordion-icon"
                        style={{cursor: "pointer"}}
                        id={`heading${lessonId}-${subLesson.id}`}
                        data-toggle="collapse"
                        data-target={`#collapse${lessonId}-${subLesson.id}`}
                        aria-expanded="false"
                        aria-controls={`collapse${lessonId}-${subLesson.id}`}
                    >
                        <svg 
                            xmlns="http://www.w3.org/2000/svg"
                            className="text-secondary chevron-down" 
                            fill="none" viewBox="0 0 24 24" stroke="currentColor"
                        >
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                        </svg>
                        <h5 className="mb-0 text-dark">
                            {
                                subLesson.name
                            }
                        </h5>
                    </div>
                    <div className="h5">
                        Satisfied / Unsatisfied
                    </div>
                </div>
                <div
                    id={`collapse${lessonId}-${subLesson.id}`}
                    className="collapse"
                    aria-labelledby={`heading${lessonId}-${subLesson.id}`}
                    data-parent={`#accordion-${lessonId}`}>
                    <div className="card-body ml-1">
                       {
                           (subLesson.modules ?? [])
                                .map(module => (
                                    <p key={lessonId + "-" + subLesson.id + "-" + module.id}>
                                            <span>
                                                <img src={module.modicon} />
                                            </span>
                                        {
                                            (module.contents ?? []).map((content, index) => (
                                                <a key={lessonId + "-" + subLesson.id + "-" + module.id + index}
                                                    target="_blank"
                                                    href={content.fileurl}>
                                                      {module.name}
                                                </a>
                                            ))
                                        }
                                    </p>
                                ))
                       }
                    </div>
                </div>
            </div>
        </div>
    )
}

export default CourseLessons

