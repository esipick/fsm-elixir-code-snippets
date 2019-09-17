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
  var appointmentOrUnavailabilityId = null;

  // change event type based on user choice
  $('a[data-toggle="tab"]').on('shown.bs.tab', function(e) {
    var id = $(e.target).get(0).id
    if (id == "navAppt") {
      $('#appointmentForm').addClass("active")
      $('#unavailabilityForm').removeClass("active")
      eventType = "appt";
    } else {
      $('#appointmentForm').removeClass("active")
      $('#unavailabilityForm').addClass("active")
      eventType = "unavail"
    }
  })

  $('#unavailInstructor').on('change', function(e) {
    $('#unavailAircraft').val(null).selectpicker("refresh")
  })

  $('#unavailAircraft').on('change', function(e) {
    $('#unavailInstructor').val(null).selectpicker("refresh")
  })

  // collect event data on save and send to server
  $('#btnSave').click(function(){

    var promise = null;

    if(eventType=="appt") {
      var eventRenter = safeParseInt($('#apptStudent').val());
      var eventInstructor = safeParseInt($('#apptInstructor').val());
      var eventAircraft = safeParseInt($('#apptAircraft').val());

      var eventStart = moment($('#apptStart').val(), displayFormat).toISOString();
      var eventEnd = moment($('#apptEnd').val(), displayFormat).toISOString();
      var eventNote = $('#apptNote').val()

      var eventData = {
        start_at: eventStart,
        end_at: eventEnd,
        user_id: eventRenter,
        instructor_user_id: eventInstructor,
        aircraft_id: eventAircraft,
        note: eventNote,
        type: "lesson"
      };

      if (appointmentOrUnavailabilityId) {
        promise = $.ajax({
          method: "put",
          url: "/api/appointments/" + appointmentOrUnavailabilityId,
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
    } else if (eventType == "unavail") {
      var eventInstructor = safeParseInt($('#unavailInstructor').val());
      var eventAircraft = safeParseInt($('#unavailAircraft').val());

      var eventStart = moment($('#unavailStart').val(), displayFormat).toISOString();
      var eventEnd = moment($('#unavailEnd').val(), displayFormat).toISOString();
      var eventNote = $('#unavailNote').val()

      var eventData = {
        start_at: eventStart,
        end_at: eventEnd,
        instructor_user_id: eventInstructor,
        aircraft_id: eventAircraft,
        note: eventNote
      };

      var promise;

      if (appointmentOrUnavailabilityId) {
        promise = $.ajax({
          method: "put",
          url: "/api/unavailabilities/" + appointmentOrUnavailabilityId,
          data: {data: eventData},
          headers: {"Authorization": window.fsm_token}
        })
      } else {
        promise = $.post({
          url: "/api/unavailabilities",
          data: {data: eventData},
          headers: {"Authorization": window.fsm_token}
        })
      }

      console.log(eventData);
    } else {
      alert('nothing selected');
    }

    if (promise) {
      promise.then(function() {
        $('#calendarNewModal').modal('hide')
        $calendar.fullCalendar('refetchEvents')

        var event;
        if (eventType == "appt") {
          event = "appointment"
        } else {
          event = "unavailability"
        }

        $.notify({
          message: "Successfully saved " + event
        }, {
          type: "success",
          placement: {align: "center"}
        })
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
    }

  });


  $('#btnDelete').click(function() {
    if (appointmentOrUnavailabilityId) {
      var promise = null;

      if (eventType == "appt") {
        promise = $.ajax({
          method: "delete",
          url: "/api/appointments/" + appointmentOrUnavailabilityId,
          headers: {"Authorization": window.fsm_token}
        })
      } else {
        promise = $.ajax({
          method: "delete",
          url: "/api/unavailabilities/" + appointmentOrUnavailabilityId,
          headers: {"Authorization": window.fsm_token}
        })
      }

      promise.then(function() {
        $('#calendarNewModal').modal('hide')
        $calendar.fullCalendar('refetchEvents')

        var event;
        if (eventType == "appt") {
          event = "appointment"
        } else {
          event = "unavailability"
        }

        $.notify({
          message: "Successfully deleted " + event
        }, {
          type: "success",
          placement: {align: "center"}
        })
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
              message: "There was an error deleting the event"
            }, {
              type: "danger",
              placement: {align: "center"}
            })
        }
      })
    }
  });





  var openAppointmentModal = function (initialData) {
    appointmentOrUnavailabilityId = initialData.id;

    if (appointmentOrUnavailabilityId) {
      $('#apptTabs').hide()
      $('#btnDelete').show()
    } else {
      $('#apptTabs').show()
      $('#btnDelete').hide()
    }

    if (initialData.type == "unavailability") {
      $('#navUnavail').tab("show")
      if (appointmentOrUnavailabilityId) {
        $('#apptTitle').text("Edit Unavailability")
      } else {
        $('#apptTitle').text("Create New")
      }
    } else {
      $('#navAppt').tab("show")
      if (appointmentOrUnavailabilityId) {
        $('#apptTitle').text("Edit Appointment")
      } else {
        $('#apptTitle').text("Create New")
      }
    }

    $('#apptStart').val(initialData.start_at.format(displayFormat))
    $('#apptEnd').val(initialData.end_at.format(displayFormat))
    $('#apptStudent').val(initialData.user_id).selectpicker("refresh");
    $('#apptInstructor').val(initialData.instructor_user_id).selectpicker("refresh");
    $('#apptAircraft').val(initialData.aircraft_id).selectpicker("refresh");
    $('#apptNote').val(initialData.note);

    $('#unavailStart').val(initialData.start_at.format(displayFormat))
    $('#unavailEnd').val(initialData.end_at.format(displayFormat))
    $('#unavailInstructor').val(initialData.instructor_user_id).selectpicker("refresh");
    $('#unavailAircraft').val(initialData.aircraft_id).selectpicker("refresh");
    $('#unavailNote').val(initialData.note);

    $('#calendarNewModal').modal();
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
        viewRender: function(view, element) { },        
        customButtons: {
          chooseDateButton: {
            text: "Choose Date",
            click: function(e) {
              // alert("JONAS!");

            }
          }
        },
        header: {
          left: 'title,chooseDateButton',
          center: 'timelineDay,timelineWeek,timelineMonth',
          right: 'prev,next,today'
        },
        resourceGroupField: "type",
        resources: resources,
        defaultView: "timelineDay",
        defaultDate: today,
        selectable: true,
        selectHelper: true,
        height: "auto",
        views: {
            month: { // name of view
                titleFormat: 'MMMM YYYY'
                // other view-specific options here
            },
            week: {
                titleFormat: " MMMM D, YYYY"
            },
            day: {
                titleFormat: 'ddd D MMM, YYYY'
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
            end_at: moment(start).add(1, 'hours'),
            instructor_user_id: instructorId,
            aircraft_id: aircraftId
          })

        },
        editable: true,
        eventClick: function(calEvent, jsEvent, view){

          if (calEvent.unavailability) {
            var instructor_user_id = null;
            if (calEvent.unavailability.instructor_user) {
              instructor_user_id = calEvent.unavailability.instructor_user.id
            }

            var aircraft_id = null;
            if (calEvent.unavailability.aircraft) {
              aircraft_id = calEvent.unavailability.aircraft.id
            }

            openAppointmentModal({
              type: "unavailability",
              start_at: moment(calEvent.unavailability.start_at),
              end_at: moment(calEvent.unavailability.end_at),
              instructor_user_id: instructor_user_id,
              aircraft_id: aircraft_id,
              note: calEvent.unavailability.note,
              id: calEvent.unavailability.id
            })
            return;
          } else if (calEvent.appointment) {
            var instructor_user_id = null;
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
              note: calEvent.appointment.note,
              user_id: calEvent.appointment.user.id,
              id: calEvent.appointment.id
            })
          }

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
            url: "/api/unavailabilities?from=" + startStr + "&to=" + endStr + "&walltime=true",
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
  }
  initDateTimePicker();
});
