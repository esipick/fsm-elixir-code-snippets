defmodule Flight.CurriculumCreator do
  alias Flight.Curriculum.{
    Course,
    CourseDownload,
    Lesson,
    LessonCategory,
    Objective,
    ObjectiveScore,
    ObjectiveNote
  }

  alias Flight.Repo

  def delete_all_courses(
        true = _sure?,
        true = _you_might_regret_this,
        true = _i_take_no_responsibility_for_your_actions
      ) do
    Repo.transaction(fn ->
      Repo.delete_all(ObjectiveNote)
      Repo.delete_all(ObjectiveScore)
      Repo.delete_all(Objective)
      Repo.delete_all(LessonCategory)
      Repo.delete_all(Lesson)
      Repo.delete_all(CourseDownload)
      Repo.delete_all(Course)
    end)
  end

  def create_course(data) do
    Repo.transaction(fn ->
      course =
        %Course{}
        |> Course.changeset(%{name: data.name})
        |> Repo.insert!()

      for {download, index} <- Enum.with_index(data.downloads) do
        %CourseDownload{}
        |> CourseDownload.changeset(%{
          name: download.name,
          url: download.url,
          course_id: course.id,
          order: index * 100
        })
        |> Repo.insert!()
      end

      for {lesson_map, index} <- Enum.with_index(data.lessons) do
        lesson =
          %Lesson{}
          |> Lesson.changeset(%{
            name: lesson_map.name,
            course_id: course.id,
            syllabus_url: lesson_map.syllabus_url,
            order: index * 100
          })
          |> Repo.insert!()

        for {lesson_category_map, index} <- Enum.with_index(lesson_map.categories) do
          lesson_category =
            %LessonCategory{}
            |> LessonCategory.changeset(%{
              name: lesson_category_map.name,
              order: index * 100,
              lesson_id: lesson.id
            })
            |> Repo.insert!()

          objectives =
            lesson_category_map.raw_objectives
            |> String.trim()
            |> String.split("\n")
            |> Enum.map(&String.trim/1)

          if Enum.empty?(objectives) do
            raise "Objectives empty for lesson #{index} in #{lesson_category.name}"
          end

          for {objective, index} <- Enum.with_index(objectives) do
            %Objective{}
            |> Objective.changeset(%{
              name: objective,
              order: index * 100,
              lesson_category_id: lesson_category.id
            })
            |> Repo.insert!()
          end
        end
      end
    end)
  end
end

defmodule Flight.CurriculumTemplate do
  def raw_private_pilot() do
    %{
      name: "Private Pilot License",
      downloads: [
        %{
          name: "Airman Certification Standards",
          url: "https://www.faa.gov/training_testing/testing/acs/media/private_airplane_acs.pdf"
        },
        %{
          name: "Weight & Balance Handbook",
          url:
            "https://www.faa.gov/regulations_policies/handbooks_manuals/aviation/media/FAA-H-8083-1.pdf"
        },
        %{
          name: "Tips on Mountain Flying",
          url:
            "https://www.faa.gov/regulations_policies/handbooks_manuals/aviation/media/tips_on_mountain_flying.pdf"
        }
      ],
      lessons: [
        %{
          name: "Lesson 1",
          syllabus_url: "https://d.pr/f/eFnp1q+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Aircraft Documents OnBoard (L1)
              Positive Exchange of Flight Controls (L1)
              Aircraft Servicing & Log Book
              Fuel Grades & Colors (L1)
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Preflight Inspection
              Engine Starting
              Brake Check
              Taxiing
              Crosswind Taxi
              Normal Takeoff, Climb, & Trim
              Straight and Level Flight
              Normal Approach & Landing
              After Landing Check
              Engine Shut Down
              Parking, Securing, & Proper Tie Down
              """
            }
          ]
        },
        %{
          name: "Lesson 2",
          syllabus_url: "https://d.pr/f/5KyssW+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Airport Environment
              Taxi Sign
              Situational Awareness
              Fitness for Flight
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Aircraft Documents on Board
              Positive Exchange of Flight Controls
              Preflight Inspection/Use of Checklist
              Taxi, Brake Check
              Engine Starting
              Taxi, Brake Check
              Normal Takeoff, Climb, & Trim
              Ground Effect
              Straight and Level Flight
              Turns to Headings
              Normal Approach & Landing
              After Landing Check
              Parking, Securing, & Proper Tie Down
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Passenger Briefing
              Collision Avoidance Precautions for Taxi
              Radio Communication
              Airspeeds at Different Configurations
              Climbs and Descents
              Use of Trim
              Traffic Pattern (Set up a link to the ground lesson)
              """
            }
          ]
        },
        %{
          name: "Lesson 3",
          syllabus_url: "https://d.pr/f/m349Az+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Airplane Sections
              Aircraft Systems
              Landing Gear Struts & Brakes
              Minimum Equipment Check
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Pre-Flight Inspection/Checklists
              Engine Starting
              Takeoff & Landings
              Passenger Briefing
              Collision Avoidance Precautions for Taxi
              Radio Communications
              Airspeeds at Different Configurations
              Approaches to Land
              Traffic Patterns
              Taxi Signs
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Constant Airspeed Climbs/Descents
              Climbs/Descents to Altitudes
              Turns to Headings
              Attitute Flying
              Airspeed Transitions
              Climbing Turns
              Descending Turns
              Effects of Flaps (Climbs & Descents)
              """
            }
          ]
        },
        %{
          name: "Lesson 4",
          syllabus_url: "https://d.pr/f/q2KcKh+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Situational Awareness (L1)
              Scanning for Traffic (L2)
              Wake Turbulence (L8)
              Wind Shear (L8)
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Effects of Flaps
              Radio Communication
              Traffic Pattern
              Constant Airspeed Climbs & Descents
              Turns to Headings
              Airspeed Transitions
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Slow Flight Maneuvers
              Stall Awareness
              Power On Stalls
              Power Off Stalls
              Stall Recovery
              Spin Awareness
              Entering Stalls from Turns
              Steep Turns (Video)
              """
            }
          ]
        },
        %{
          name: "Lesson 5",
          syllabus_url: "https://d.pr/f/QAHExL+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Finding Wind Direction
              Workload Management
              Aeronautical Decision Making
              Pilot-in-Command Responsibilities
              Airpane Stability
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Normal Takeoff and Landings
              Constant Airspeed Climbs/Descents
              Power On/Off Stalls
              Slow Flight
              Steep Turns
              Taxiway Markings & Lighting
              Airspeed Transitions
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Finding Wind Directions (Video)
              Rectangular Courses (Video)
              Turn Around a Point (Video)
              S-Turns (Video)
              Accelerated Stalls
              Cross Controlled Stall
              Secondary Stall
              Elevator Stall
              """
            }
          ]
        },
        %{
          name: "Lesson 6",
          syllabus_url: "https://d.pr/f/tZ4YP8+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Left Turning Tendencies
              Crosswind Taxi
              Crosswind Takeoff & Landings
              Wake Turbulence Avoidance
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Steep Turns
              Stalls Power On/Off
              Normal Takeoff & Landing
              Slow Flight
              Rectangular Courses
              Turns Around a Point
              S-Turns
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Go-Around Landing
              Rejected Takeoff
              Forward Slips
              Crosswind Taxi
              Crosswind Takeoff & Climb
              Crosswind Approach & Landing
              Constant Rate Climb
              Constant Rate Descent
              """
            }
          ]
        },
        %{
          name: "Lesson 7",
          syllabus_url: "https://d.pr/f/lE4ARs+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Emergency Gear and Preparedness
              Land and Hold Short Operations (LAHSO)
              Emergency Preparedness
              Lost Communication Procedures
              ATC Light Signal
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Normal Takeoffs & Landings
              Forward Slips to Land
              Positive Exchange of Flight Controls
              Constant Rate Descent
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Runway Incursion Avoidance
              System Malfunctions
              Emergency Procedures, Approach & Landing
              Emergency Descents
              In-Flight Fire
              Wake Turbulence Avoidance
              """
            }
          ]
        },
        %{
          name: "Lesson 8",
          syllabus_url: "https://d.pr/f/YfaXiO+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Pre-Solo Written Exam Review
              Regulations and Procedures for your airport
              Overview of Solo flight
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Slow Flight
              Power On/Off Stalls
              Steep Turns
              Climbing and Descending Turns
              Cross Wind Takeoff & Landings
              Runway Incursion Avoidance
              Land and Hold Short Operations (LAHSO)
              Rectangular Courses
              S-Turns
              Turns Around a Point
              Systems & Equipment Failure
              Emergency Procedures, Approach & Landing
              In-Flight Fire
              Go-Arounds
              Forward Slips
              """
            }
          ]
        },
        %{
          name: "Lesson 9",
          syllabus_url: "https://d.pr/f/17vFml+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Pre-Solo Written Exam Review and Critique
              Correct any Incorrect Answers
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Radio Communication
              Cross Wind Taxi
              Traffic Pattern
              Go-Arounds
              Crosswind Takeoff/Landings
              Forward Slips to Land
              Wake Turbulence Avoidance
              Systems & Equipment Failure
              Rejected Takeoffs
              Emergency Approach & Landing
              Emergency Procedures
              Spin Awareness
              Any other Necessary Training
              """
            }
          ]
        },
        %{
          name: "Lesson 10",
          syllabus_url: "https://d.pr/f/vXHvjL+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Any training suggested by the instructor
              Answer any student questions
              Pilot-in-Command Responsibilities
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Engine Starting
              Taxi
              Traffic Pattern
              3 Normal Approach to Landings
              Emergency Landing
              Go-Arounds
              Rejected Takeoff
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Radio Communication
              Taxiing
              Pre-Takeoff Procedures
              3 Normal Takeoff and Landings
              Traffic Patterns
              After landing and Securing the Airplane Procedures
              """
            }
          ]
        },
        %{
          name: "Lesson 11",
          syllabus_url: "https://d.pr/f/Z6Z3yA+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Airworthiness
              Certificates & Documents
              Minimum Equipment Check
              Aircraft Logbooks
              Maneuvers
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Use of Checklists
              Pre-Flight Inspection
              Engine Starting
              Radio Communication
              Taxiing
              Normal Takeoff and Landings
              Cross Wind Takeoff and Landings
              Go-Arounds
              Traffic Pattern
              Collision Avoidance Precautions
              Slow Flight
              Power On/Off Stalls
              Spin Awareness
              Systems & Equipment Failure
              Emergency Procedures
              Emergency Landing
              """
            }
          ]
        },
        %{
          name: "Lesson 12",
          syllabus_url: "https://d.pr/f/6tNUEM+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Aircraft Performance Chart & Limitations
              Weight & Balance
              Density Altitudes
              Airspeeds
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Slow Flight
              Stalls Power On/Off
              S-Turns
              Rectangular Courses
              Turns Around a Point
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Short Field Takeoff & Climb
              Soft Field Takeoff & Climb
              Short Field Approach & Landing
              Soft Field Approach & Landing
              """
            }
          ]
        },
        %{
          name: "Lesson 13",
          syllabus_url: "https://d.pr/f/7KIeNQ+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Runway Incursion Precautions
              Workload Management
              Realistic Distractions
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Low Level Wind Shear Avoidance
              Slow Flight
              Power On/Off Stalls
              Steep Turns
              Forward Slip to Land
              Short Field Takeoff & Climb
              Soft Field Takeoff & Climb
              Short Field Approach & Landing
              Soft Field Approach & Landing
              """
            }
          ]
        },
        %{
          name: "Lesson 14",
          syllabus_url: "https://d.pr/f/pHIia9+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Any training suggested by the Instructor
              Airport Operations & Procedures
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Taxiing
              Normal Takeoff and Landings
              Traffic Pattern
              Parking and Securing the Airplane
              Short Field Takeoff & Climb
              Short Field Approach & Landing
              """
            }
          ]
        },
        %{
          name: "Lesson 15",
          syllabus_url: "https://d.pr/f/sUsv09+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Any training suggested by the Instructor
              Any Student Questions
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Radio Communication
              Slow Flight
              Power On/Off Stalls
              Steep Turns
              S-Turns
              Rectangular Courses
              Turns Around a Point
              Crosswind Takeoff & Landings
              Forward Slips to Land
              Soft Field Takeoff & Climb
              Soft Field Approach & Landing
              Other Necessary Practice
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Radio Communication
              Slow Flight
              Power On/Off Stalls
              Steep Turns
              S-Turns
              Rectangular Courses
              Turns Around a Point
              Crosswind Takeoff & Landings
              Forward Slips to Land
              Soft Field Takeoff & Climb
              Soft Field Approach & Landing
              Other Necessary Practice
              """
            }
          ]
        },
        %{
          name: "Lesson 16",
          syllabus_url: "https://d.pr/f/YQYpAh+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Instrument Maneuvers
              Navigational Facilities, Systems, and Radar Services
              Disorientation
              Flying into Weather
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Short Field Takeoff & Climbs
              Soft Field Takeoff & Climbs
              Short Field Approach to Landings
              Soft Field Approach to Landings
              Forward Slips to Land
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Straight & Level Flight (Simulated Instrument)
              Constant Airspeed Climbs (Simulated Instrument)
              Constant Airspeed Descents (Simulated Instrument)
              Slow Flight (Simulated Instrument)
              VOR Tracking & Orientation
              Navigation Systems & Facilities
              Recovery from Unusual Attitudes
              """
            }
          ]
        },
        %{
          name: "Lesson 17",
          syllabus_url: "https://d.pr/f/q0QcWS+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Inadvertent Flight into IFR
              Partial Panel
              Common Errors & Limitations
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              VOR Tracking
              Slow Flight (VFR, Simulated Instrument)
              Go-Arounds
              Emergency Procedures
              Crosswind Takeoffs & Landings
              Recovery from Unusual Attitudes
              Navigation Systems & Facilities
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              ADF Orientation
              Power On/Off Stalls (Simulated Instrument)
              Recovery from  Unusual Flight Attitude (Simulated Instrument)
              """
            }
          ]
        },
        %{
          name: "Lesson 18",
          syllabus_url: "https://d.pr/f/XAH5HZ+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Sectional Chart
              Course Selection
              Navigation (Plotting, Dead Reckoning, Pilotage)
              Obtaining Weather Information
              Performance Charts & Planning
              Navigation Log
              PIC Responsibilities
              Aeronautical Decision Making
              Workload Management
              Situational Awareness
              Resource Management
              Cockpit Management
              Cross Country Flight Procedures (Open/Close Flight Plan, Communication w/Radar & FSS, PIREPS)
              AF/D & Other Publications
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Emergency Procedures
              Systems & Equipment Failure
              Lost Procedures
              Weight & Balance
              Instrument Maneuvers
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Flight Planning
              Opening Flight Plan
              Intercepting Course
              Power Settings & Mixture
              Pilotage
              Dead Reckoning
              VOR Navigation (VFR, Simulated Instrument)
              ADF Navigation (VFR, Simulated instrument)
              Radar Services
              Alternate Airports
              Estimate Ground Speed (GS), Fuel Consumption, and ETA
              Communication with Flight Service Station (FSS)
              Using Magnetic Compass
              Airspace
              ATIS and/or AWOS
              CTAF and/or Approach & Departure Control
              Flying Federal Airways
              Closing  Flight Plan
              """
            }
          ]
        },
        %{
          name: "Lesson 19",
          syllabus_url: "https://d.pr/f/Uaoz9Y+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Night Vision
              Visual Illusions
              Aero Medical Factors
              Aircraft Lighting
              Airport & Obstruction Lighting
              Equipment List
              Personal Equipment
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Introduce Night Flying
              Flight Planning for Night
              Night Takeoffs and Landings
              Go-Arounds at Night
              Emergency Procedures at Night
              Preflight Inspections
              Taxiing
              Before Takeoff Check
              Power On/Off Stalls
              Slow Flight
              Steep Turns
              Night Navigation
              """
            }
          ]
        },
        %{
          name: "Lesson 20",
          syllabus_url: "https://d.pr/f/EVj7xb+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Night Flying Procedures
              Obtaining Weather
              Altitude Selection
              Aeromedical Factors
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Night Flight Equipment
              Night Flight Preparation
              Fuel Requirements
              Night Vision
              Cross Country Flight Procedures (Open/Close Flight Plan, Communication w/Radar & FSS, PIREPS)
              Enroute Weather Information
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Course Selection
              Pilotage
              Dead Reckoning
              Radio Navigation (VFR, Simulated Instrument)
              Lost Procedures
              Unfamiliar Airports
              Airport Lighting (Pilot Controlled)
              Emergency Procedures
              Collision Avoidance
              Basic Instrument Maneuvers
              """
            }
          ]
        },
        %{
          name: "Lesson 21",
          syllabus_url: "https://d.pr/f/hHNqMi+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Required Documents & Endorsements
              Weather Minimums
              National Airspace Regulations
              Lost Procedures
              Emergency Procedures
              Aeronautical Decision Making
              Workload Management
              ATC
              Lost Communication Procedures
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Weight & Balance
              Performance Charts
              Sectional Charts
              Fuel Requirements & Estimations
              Navigation Log
              Weather Information
              Cross Country Procedures (Open/Close Flight Plan, etc)
              AF/D & Other Publications
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Intercepting Selected Course
              Opening Flight Plan
              Pilotage
              Dead Reckoning
              VOR and/or ADF Navigation
              Flight On Federal Airway
              Estimated Ground Speed (GS), Fuel Consumption, and ETA
              Radio Communication (CTAF)
              Closing Flight Plan
              """
            }
          ]
        },
        %{
          name: "Lesson 22",
          syllabus_url: "https://d.pr/f/90XUpu+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Low Level Wind Shear
              Wake Vortices
              Cross Country Flight Planning
              Obtaining Weather
              Airspace Rules & Regulations
              Certificates & Documents
              Performance Charts
              Airplane Systems
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Airport Environment & Taxi Signs
              Preflight Inspection/Use of Checklist
              Cockpit Management
              Situational Awareness
              Resource Use
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              Short Field Takeoff Max Performance Climb
              Soft Field Takeoff & Climb
              Short Field Approach & Landings
              Soft Field Approach & Landings
              Course Interception
              VOR Navigation
              Pilotage
              Dead Reckoning
              Scanning for Traffic
              Lost Procedures
              Diversion
              Emergency Procedures
              System & Equipment Failure
              Power On/Off Stalls
              Slow Flight
              Steep Turns
              S-Turns
              Rectangular Courses
              Turns Around a Point
              Radio Communication
              """
            }
          ]
        },
        %{
          name: "Lesson 23",
          syllabus_url: "https://d.pr/f/9z9ZcE+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              National Airspace
              Sectional Charts
              Obtaining Weather Information
              Weight & Balance
              Navigation Log
              Performance Charts
              Course Selection
              Unfamiliar Airport Procedures
              AF/D & Other Publications
              Emergency Operations
              Any other Training Suggested by the Instructor
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Open Flight Plan
              Radio Communication (FSS & Unicom)
              VOR Navigation
              Pilotage
              Dead Reckoning
              Estimates Ground Speed, Fuel Consumption, & ETA
              Controlled Airspace
              Closing a Flight Plan
              """
            }
          ]
        },
        %{
          name: "Lesson 24",
          syllabus_url: "https://d.pr/f/8IkiZR+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Necessary preparations for the Stage 3 exam, End-of-Course Flight Check, and FAA Check ride.
              Preflight Procedures
              Ground Operations
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Pre-Flight Inspection
              Normal Takeoffs and Landings
              Short Field Takeoffs and Climbs and Landings
              Soft Field Takeoffs and Landings
              Crosswind Takeoffs and Landings
              Slow Flight (VFR & Simulated Instrument)
              Power On/Off Stalls (VFR & Simulated Instrument)
              Navigations & Radar Systems (VFR & Simulated Instrument)
              Steep Turns
              S-Turns
              Rectangular Courses
              Turns Around a Point
              Recovery from Unusual Attitudes (VFR & Simulated Instrument)
              Go-Arounds
              Forward Slips to Landings
              Emergency Procedures
              Systems and Equipment Failure
              Airports Procedures
              Parking & Securing the Airplane
              Other Necessary Training Suggested by the Instructor
              """
            }
          ]
        },
        %{
          name: "Lesson 25",
          syllabus_url: "https://d.pr/f/CPhcvy+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Necessary preparations for the Stage 3 exam, End-of-Course Flight Check, and FAA Check ride.
              Preflight Procedures
              Ground Operations
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Pre-Flight Inspection
              Normal Takeoffs and Landings
              Short Field Takeoffs and Climbs and Landings
              Soft Field Takeoffs and Landings
              Crosswind Takeoffs and Landings
              Slow Flight (VFR & Simulated Instrument)
              Power On/Off Stalls (VFR & Simulated Instrument)
              Spin Awareness
              Navigations & Radar Systems (VFR & Simulated Instrument)
              Steep Turns
              S-Turns
              Rectangular Courses
              Turns Around a Point
              Recovery from Unusual Attitudes (VFR & Simulated Instrument)
              Go-Arounds
              Forward Slips to Landings
              Emergency Procedures
              Systems and Equipment Failure
              Airports Procedures
              Parking & Securing the Airplane
              Other Necessary Training Suggested by the Instructor
              """
            }
          ]
        },
        %{
          name: "Lesson 26",
          syllabus_url: "https://d.pr/f/LrYlFe+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              National Airspace
              Other Necessary Training Suggested by the Instructor
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Airport Operations
              Communication with Tower
              Traffic Patterns
              Go Around
              """
            },
            %{
              name: "Flight Lesson",
              raw_objectives: """
              3 Solo Takeoffs and Landings at a Towered Airport
              Controlled Airspace Operations
              Other Necessary Training Suggested by the Instructor
              """
            }
          ]
        },
        %{
          name: "Lesson 27",
          syllabus_url: "https://d.pr/f/B7mxQO+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              Certificates & Documents
              Airplane Logbooks
              Airworthiness Requirements
              Operation Systems
              Maneuvers
              Aeromedical Factors
              """
            },
            %{
              name: "Flight Review",
              raw_objectives: """
              Pre-Flight Inspection
              Normal Takeoffs and Landings
              Short Field Takeoffs and Climbs and Landings
              Soft Field Takeoffs and Landings
              Crosswind Takeoffs and Landings
              Slow Flight (VFR & Simulated Instrument)
              Power On/Off Stalls (VFR & Simulated Instrument)
              Spin Awareness
              Navigations & Radar Systems (VFR & Simulated Instrument)
              Steep Turns
              S-Turns
              Rectangular Courses
              Turns Around a Point
              Recovery from Unusual Attitudes (VFR & Simulated Instrument)
              Go-Arounds
              Forward Slips to Landings
              Emergency Procedures
              Systems and Equipment Failure
              Airport Procedures
              Parking & Securing the Airplane
              Other Necessary Training Suggested by the Instructor
              Pilotage & Dead Reckoning
              Radio Navigation
              Lost Procedures
              Alternate Airports
              """
            }
          ]
        },
        %{
          name: "Lesson 28",
          syllabus_url: "https://d.pr/f/6119HM+",
          categories: [
            %{
              name: "Preflight",
              raw_objectives: """
              ATC Lights
              Airport Procedures
              Performance Requirements
              Any Other Training Suggested by the Instructor
              """
            },
            %{
              name: "Preflight Planning",
              raw_objectives: """
              Airworthiness
              Certificates & Documents
              Private Pilot Privileges
              Weather Information
              Flight Planning
              Systems
              Aeromedical Factors
              National Airspaces
              Performance & Limitations
              Weight & Balance
              """
            },
            %{
              name: "Preflight Review",
              raw_objectives: """
              Pre-Flight Inspection
              Use of Checklists
              """
            },
            %{
              name: "Ground Operations",
              raw_objectives: """
              Engine Starting
              Taxiing (Crosswind)
              Before Takeoff Check
              Radios & Avionics
              Radio Communications
              Scanning & Collision Avoidance
              Wind Shear & Wake Turbulence Avoidance
              """
            },
            %{
              name: "Takeoffs",
              raw_objectives: """
              Normal & Crosswind Takeoffs
              Short Field Takeoff & Climb Performance
              Soft Field Takeoff
              Traffic Pattern
              Straight and Level Flight (VFR & Simulated Instrument)
              Constant Airspeed Climbs and Descents (VFR & Simulated Instrument)
              Turns to Headings (VFR & Simulated Instrument)
              Climbing & Descending Turns
              """
            },
            %{
              name: "Maneuvers",
              raw_objectives: """
              Recovery from Unusual Attitudes (VFR & Simulated Instrument)
              Slow Flight
              Power On/Off Stalls
              Steep Turns
              Spin Awareness
              S-Turns
              Rectangular Courses
              Turns Around a Point
              """
            },
            %{
              name: "Emergency",
              raw_objectives: """
              Emergency Procedures
              Emergency Approach to Landings
              Systems & Equipment Failure
              Emergency Preparation and Gear
              """
            },
            %{
              name: "Landings",
              raw_objectives: """
              Normal & Crosswind Approach to Landings
              Forward Slips to Landing
              Go-Arounds
              Short Field Approach & Landings
              Soft Field Approach & Landings
              """
            }
          ]
        }
      ]
    }
  end
end
