import React, { useState } from 'react';
import { authHeaders } from '../utils';

const CourseLessons = ({ courseInfo, courseId }) => {
    const [state, setState] = useState({
        subLessonId: undefined,
        type: undefined,
        course: courseInfo,
        pageModuleContent: undefined,
    })

    const handleRemark = async (lessonId, subLessonId, remark) => {
        const payload = {
            course_id: courseId,
            lesson_id: lessonId,
            sub_lesson_id: subLessonId,
            teacher_mark: remark,
            fsm_user_id: state.course.fsm_user_id,
            notes: null
        }

        const reqOpts = {
			method: 'POST',
			headers: {
                ...authHeaders(),
				'Content-Type': 'application/json'
			},
			body: JSON.stringify(payload)
		}

        setState({
            ...state,
            type: remark,
            subLessonId: subLessonId
        })

		await fetch(`/api/course/sublesson/remarks`, reqOpts)
			.then(res => res.json())
			.then(data => {
                setState({
                    type: undefined,
                    subLessonId: undefined,
                    course: data.courseInfo
                })
			})
			.catch(error => {
                setState({
                    ...state,
                    type: undefined,
                    subLessonId: undefined
                })
                window.alert("Something went wrong, please try again.")
			})
    }

    const getModulePageContent = async (url) => {
        const reqOpts = {
			method: 'GET',
		}
		await fetch(url, reqOpts)
			.then(res => res.text())
			.then(data => {
              console.log('data',data)
                setState({
                    ...state,
                    pageModuleContent: data
                })
			})
			.catch(error => {

			})
    }

    return (<div className="card">
            <div className="card-header d-flex flex-column">
                {
                    (state.course.lessons ?? []).map(lesson => (
                        <div key={lesson.id} id={`accordion-${lesson.id}`}>
                            <div className="row my-2">
                                <div className="col-md-12 border-secondary border-bottom">
                                    <h3>{lesson.name} <span className="text-primary h-5"> </span></h3>
                                    {
                                        lesson.sub_lessons.map(subLesson => <SubLessonCard
                                            key={lesson.id +"-"+ subLesson.id}
                                            lessonId={lesson.id}
                                            subLesson={subLesson}
                                            markedSubLesson={{type: state.type, subLessonId: state.subLessonId}}
                                            setRemark={handleRemark}
                                            getModulePageContent={getModulePageContent}
                                            course={state.course}
                                            pageModuleContent={state.pageModuleContent}
                                            />
                                        )
                                    }
                                </div>
                            </div>
                        </div>
                    ))
                }
            </div>
      </div>
    )
}

const SubLessonCard = ({lessonId, subLesson,markedSubLesson, setRemark,getModulePageContent,course, pageModuleContent}) => {
    console.log('course',course)

    const isSatisfied = subLesson.remarks === "satisfactory"
    const isUnsatisfied = subLesson.remarks === "not_satisfactory"

    return (
        <div className="border-secondary border-bottom">
            <div className="py-4 mx-3">
                <div className="row ml-0 d-flex flex-row justify-content-between">
                    <div className="row accordion-icon cursor-pointer"
                        id={`heading${lessonId}-${subLesson.id}`}
                        data-toggle="collapse"
                        data-target={`#collapse${lessonId}-${subLesson.id}`}
                        aria-expanded="false"
                        aria-controls={`collapse${lessonId}-${subLesson.id}`}
                    >
                        <ChevronDown />
                        <h5 className="mb-0 text-dark">
                            {
                                subLesson.name
                            }
                        </h5>
                    </div>
                    <div className="h5 d-flex flex-row">

                        {
                            markedSubLesson.type === 1 && markedSubLesson.subLessonId === subLesson.id ?
                                <Spinner />
                                :
                                <div className={`button-remark ${ isSatisfied ? 'active disabled-click' : ''}`} disabled={isSatisfied}
                                    onClick={() =>setRemark(lessonId, subLesson.id, 1)}>Statisfied</div>
                        }
                         {
                            markedSubLesson.type === 2 && markedSubLesson.subLessonId === subLesson.id ?
                                <Spinner />
                                :
                                <div className={`button-remark ${ isUnsatisfied ? 'active disabled-click' : ''}`} disabled={isUnsatisfied}
                                    onClick={() =>setRemark(lessonId, subLesson.id, 2)}>Unstatisfied</div>
                        }
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
                                            (module.contents ?? []).map((content, index) => {
                                                if(module.modname == 'page'){
                                                    return <a key={lessonId + "-" + subLesson.id + "-" + module.id + index}
                                                              onClick={() =>getModulePageContent(content.fileurl + "&token=" + course.token)}>
                                                        {module.name}
                                                    </a>

                                                }else{
                                                    return <a key={lessonId + "-" + subLesson.id + "-" + module.id + index}
                                                              href={content.fileurl + "&token=" + course.token}>
                                                        {module.name}
                                                    </a>
                                                }



                                            })
                                        }
                                    </p>
                                ))
                       }
                    </div>
                    <p dangerouslySetInnerHTML={{__html: pageModuleContent}} />
                </div>
            </div>
        </div>
    )
}
const ChevronDown = () => (<svg 
    xmlns="http://www.w3.org/2000/svg"
    className="text-secondary chevron-down" 
    fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
</svg>)

const Spinner = () => (<div className="lds-ring"><div></div><div></div><div></div><div></div></div>)

export default CourseLessons

