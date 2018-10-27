/* global $, swal, moment */

$(document).ready(function() {

  var fullName = function(user) {
    return user.first_name + " " + user.last_name
  }

  var safeParseInt = function (num) {
    if (num) {
      return parseInt(num)
    } else {
      return null
    }
  }

  var $calendar = $('#fullCalendar');
  
  var displayFormat = 'MM/DD/YYYY h:mm A';
  
  // dynamic unavailability form
  var unavailType = 'Instructor';
  $('#fieldAircraft').hide(); // hide aircraft by default
  $('#unavailFor').on('change', function() {
    unavailType=this.value;
    if(this.value == "Aircraft"){
      $('#fieldAircraft').show();
      $('#fieldInstructor').hide();
    }else if(this.value == "Instructor"){
      $('#fieldAircraft').hide();
      $('#fieldInstructor').show();
    }
  });

  var eventType = "appt";
  var appointmentId = null;

  // change event type based on user choice
  $('#navAppt').click(function(){
    eventType="appt";  
  });
  $('#navUnavail').click(function(){
    eventType="unavail";  
  });

  // collect event data on save and send to server
  $('#btnSave').click(function(){
    
    if(eventType=="appt") {
      var eventRenter = safeParseInt($('#apptStudent').val());
      var eventInstructor = safeParseInt($('#apptInstructor').val());
      var eventAircraft = safeParseInt($('#apptAircraft').val());
      
      var eventStart = moment($('#apptStart').val(), displayFormat).toISOString();
      var eventEnd = moment($('#apptEnd').val(), displayFormat).toISOString();

      var eventData = {
        start_at: eventStart,
        end_at: eventEnd,
        user_id: eventRenter,
        instructor_user_id: eventInstructor,
        aircraft_id: eventAircraft
      };

      var promise;

      if (appointmentId) {
        promise = $.ajax({
          method: "put",
          url: "/api/appointments/" + appointmentId, 
          data: {data: eventData}, 
          headers: {"Authorization": window.fsm_token}
        })
      } else {
        promise = $.post({
          url: "/api/appointments", 
          data: {data: eventData}, 
          headers: {"Authorization": window.fsm_token}
        })
      }

      promise.then(function() {
        $('#calendarNewModal').modal('hide')
        $calendar.fullCalendar('refetchEvents')
      }).catch(function(e) {
        if (e.responseJSON.human_errors) {
          for(var error of e.responseJSON.human_errors) {
            $.notify({
              message: error
            }, {
              type: "danger", 
              placement: {align: "center"}
            })
          }
        } else {
            $.notify({
              message: "There was an error creating the event"
            }, {
              type: "danger", 
              placement: {align: "center"}
            })
        }
      })
      console.log(eventData);
      
      // $calendar.fullCalendar('unselect');
    } else if (eventType == "unavail") {
      var titleDescription = ' — Unavailable';
      
      if (unavailType == 'Aircraft'){
        var event_title = $('#unavailAircraft').val() + titleDescription;
      } else {
        var event_title = $('#unavailInstructor').val() + titleDescription;  
      }
      
      var event_start = $('#unavailStart').val();
      var event_end = $('#unavailEnd').val();
      
      if (event_title) {
        eventData = {
          title: event_title,
          start: event_start,
          end: event_end,
          className: 'event-default'
        };
        console.log(eventData);
        $calendar.fullCalendar('renderEvent', eventData, true);
      }
      
      $calendar.fullCalendar('unselect');
    } else {
      alert('nothing selected');
    }
    
  });







  var openAppointmentModal = function (initialData) {
    console.log("Initial data: ", initialData)
    $('#calendarNewModal').modal();

    appointmentId = initialData.id;

    if (appointmentId) {
      $('#apptTitle').text("Edit Appointment")
      $('#apptTabs').hide()
    } else {
      $('#apptTitle').text("Create New")
      // Temporary while getting unavailability to work
      $('#apptTabs').hide()
    }

    $('#apptStart').val(initialData.start_at.format(displayFormat))
    $('#apptEnd').val(initialData.end_at.format(displayFormat))
    $('#apptStudent').val(initialData.user_id).selectpicker("refresh");
    $('#apptInstructor').val(initialData.instructor_user_id).selectpicker("refresh");
    $('#apptAircraft').val(initialData.aircraft_id).selectpicker("refresh");
  };







  

  function fsmCalendar(instructors, aircrafts) {

      var resources = instructors.map(function(instructor) {
        return {
          id: "instructor:" + instructor.id,
          type: "Instructors",
          title: fullName(instructor)
        }
      })

      resources = resources.concat(aircrafts.map(function(aircraft) {
        return {
          id: "aircraft:" + aircraft.id,
          type: "Aircrafts",
          title: aircraft.make + " " + aircraft.tail_number
        }
      }))

      var today = new Date();
      var y = today.getFullYear();
      var m = today.getMonth();
      var d = today.getDate();

      $calendar.fullCalendar({
        viewRender: function(view, element) {
          // We make sure that we activate the perfect scrollbar when the view isn't on Month
          if (view.name != 'month'){
            $(element).find('.fc-scroller').perfectScrollbar();
          }
        },
        header: {
          left: 'title',
          center: 'timelineDay,month,listWeek',
          right: 'prev,next,today'
        },
        resourceGroupField: "type",
        resources: resources,
        defaultView: "timelineDay",
        defaultDate: today,
        selectable: true,
        selectHelper: true,
        views: {
            month: { // name of view
                titleFormat: 'MMMM YYYY'
                // other view-specific options here
            },
            week: {
                titleFormat: " MMMM D YYYY"
            },
            day: {
                titleFormat: 'D MMM, YYYY'
            }
        },

        select: function(start, end, notSure, notSure2, resource) {
          var instructorId = null;
          var aircraftId = null;

          if (resource) {
            var split = resource.id.split(":")
            var type = split[0]
            var id = parseInt(split[1])
            if (type == "instructor") {
              instructorId = id
            } else if (type == "aircraft") {
              aircraftId = id
            }
          }
          
          var eventType="appt"; // setting default event type to appt
          var eventData;
          var thatsAllDay = false;

          openAppointmentModal({
            start_at: start,
            end_at: end,
            instructor_user_id: instructorId,
            aircraft_id: aircraftId
          })
          
        },
        editable: true,
        eventClick: function(calEvent, jsEvent, view){
          var instructor_user_id = null;

          if (calEvent.unavailability) {
            return;
          }

          if (calEvent.appointment.instructor_user) {
            instructor_user_id = calEvent.appointment.instructor_user.id
          }

          var aircraft_id = null;

          if (calEvent.appointment.aircraft) {
            aircraft_id = calEvent.appointment.aircraft.id
          }

          openAppointmentModal({
            start_at: moment(calEvent.appointment.start_at),
            end_at: moment(calEvent.appointment.end_at),
            instructor_user_id: instructor_user_id,
            aircraft_id: aircraft_id,
            user_id: calEvent.appointment.user.id,
            id: calEvent.appointment.id
          })
        },
        
        
        eventLimit: true, // allow "more" link when too many events

        // color classes: [ event-blue | event-azure | event-green | event-orange | event-red ]
        events: function(start, end, timezone, callback) {
          var startStr = moment(start).toISOString()
          var endStr = moment(end).toISOString()
          var appointmentsPromise = $.get({
            url: "/api/appointments?from=" + startStr + "&to=" + endStr + "&walltime=true", 
            headers: {"Authorization": window.fsm_token}
          })

          var unavailabilityPromise = $.get({
            url: "/api/unavailabilities?from=" + startStr + "&to=" + endStr, 
            headers: {"Authorization": window.fsm_token}
          })
          
          
          Promise.all([appointmentsPromise, unavailabilityPromise]).then(function(resp) {

            var appointments = resp[0].data.map(function(appointment) {
              var resourceIds = []

              if (appointment.instructor_user) {
                resourceIds.push("instructor:" + appointment.instructor_user.id)
              }

              if (appointment.aircraft) {
                resourceIds.push("aircraft:" + appointment.aircraft.id)
              }

              return {
                title: appointment.user.first_name + " " + appointment.user.last_name,
                start: moment(appointment.start_at),
                end: moment(appointment.end_at),
                id: "appointment:" + appointment.id,
                appointment: appointment,
                resourceIds: resourceIds,
                className: 'event-blue'
              }
            })

            var unavailabilities = resp[1].data.map(function(unavailability) {
              var resourceIds = []

              if (unavailability.instructor_user) {
                resourceIds.push("instructor:" + unavailability.instructor_user.id)
              }

              if (unavailability.aircraft) {
                resourceIds.push("aircraft:" + unavailability.aircraft.id)
              }

              return {
                title: "Unavailable",
                start: moment(unavailability.start_at),
                end: moment(unavailability.end_at),
                id: "unavailability:" + unavailability.id,
                unavailability: unavailability,
                resourceIds: resourceIds,
                className: 'event-default'
              }
            })
            callback(appointments.concat(unavailabilities))
          })
        }
      });
  }

  var users = $.get({url: "/api/users?form=directory", headers: {"Authorization": window.fsm_token}})
  var aircrafts = $.get({url: "/api/aircrafts", headers: {"Authorization": window.fsm_token}})

  Promise.all([users, aircrafts]).then(function(values) {
    var instructors = values[0].data.filter(function(user) {
      return user.roles.indexOf("instructor") != -1
    });

    fsmCalendar(instructors, values[1].data);
  });


  function initDateTimePicker() {
    $('.datetimepickerstart').datetimepicker({
        // debug: true,
        stepping: 30,
        icons: {
            time: "now-ui-icons tech_watch-time",
            date: "now-ui-icons ui-1_calendar-60",
            up: "fa fa-chevron-up",
            down: "fa fa-chevron-down",
            previous: 'now-ui-icons arrows-1_minimal-left',
            next: 'now-ui-icons arrows-1_minimal-right',
            today: 'fa fa-screenshot',
            clear: 'fa fa-trash',
            close: 'fa fa-remove'
        }
    });
    $('.datetimepickerend').datetimepicker({
        // debug: true,
        useCurrent: false, //Important! See issue #1075
        stepping: 30,
        icons: {
          time: "now-ui-icons tech_watch-time",
          date: "now-ui-icons ui-1_calendar-60",
          up: "fa fa-chevron-up",
          down: "fa fa-chevron-down",
          previous: 'now-ui-icons arrows-1_minimal-left',
          next: 'now-ui-icons arrows-1_minimal-right',
          today: 'fa fa-screenshot',
          clear: 'fa fa-trash',
          close: 'fa fa-remove'
        }
    });
    $(".datetimepickerstart").on("dp.change", function (e) {
        $('.datetimepickerend').data("DateTimePicker").minDate(e.date);
    });
    $(".datetimepickerend").on("dp.change", function (e) {
        $('.datetimepickerstart').data("DateTimePicker").maxDate(e.date);
    });

  }
  initDateTimePicker();







});

