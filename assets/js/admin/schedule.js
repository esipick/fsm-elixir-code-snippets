/* global $, swal, moment */

function userTitle(user) {
  if (!user) return '';

  return `${user.first_name} ${user.last_name}`;
}

function appointmentTitle(appointment) {
  return (appointment.demo) ? "Demo Flight" : userTitle(appointment.user) || userTitle(appointment.instructor_user);
}

function payerTitle(appointment) {
  return (appointment.demo) ? appointment.payer_name : userTitle(appointment.user) || userTitle(appointment.instructor_user);
}

$(document).ready(function () {

  var AUTH_HEADERS = { "Authorization": window.fsm_token };
  var meta_roles = document.head.querySelector('meta[name="roles"]');

  var fullName = function (user) {
    return user.first_name + " " + user.last_name
  }

  var safeParseInt = function (num) {
    if (num) {
      return parseInt(num)
    } else {
      return null
    }
  }

  var addSchoolIdParam = (prefix = '', postfix = '') => {
    let span = document.getElementById('current-school')

    if (span) {
      return prefix + "school_id=" + span.dataset.schoolId + postfix
    } else { return '' }
  }

  var $calendar = $('#fullCalendar');

  var displayFormat = 'MM/DD/YYYY h:mm A';

  // dynamic unavailability form
  var unavailType = 'Instructor';
  $('#fieldAircraft').hide(); // hide aircraft by default
  $('#fieldSimulator').hide(); // hide simulator by default
  $('#fieldRoom').hide(); // hide room by default

  $('#unavailFor').on('change', function () {
    displayForUnavailability(this.value)
  });

  function displayForUnavailability(type) {
    if (type == "Aircraft") {
      $('#fieldAircraft').show();
      $('#fieldInstructor').hide();
      $('#fieldSimulator').hide();
      $('#fieldRoom').hide();

    } else if (type == "Instructor") {
      $('#fieldAircraft').hide();
      $('#fieldInstructor').show();
      $('#fieldSimulator').hide();
      $('#fieldRoom').hide();

    } else if (type == "Simulator") {
      $('#fieldAircraft').hide();
      $('#fieldInstructor').hide();
      $('#fieldSimulator').show();
      $('#fieldRoom').hide();

    } else if (type == "Room") {
      $('#fieldAircraft').hide();
      $('#fieldInstructor').hide();
      $('#fieldSimulator').hide();
      $('#fieldRoom').show();
    }
  }

  var eventType = "appt";
  var appointmentId = null;
  var appointmentOrUnavailabilityId = null;

  // change event type based on user choice
  $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    var id = $(e.target).get(0).id

    if (id == "navAppt") {
      $('#appointmentForm.tab-pane').addClass("active");
      $('#unavailabilityForm.tab-pane').removeClass("active")
      $('#demoAppointmentForm.tab-pane').removeClass("active")
      eventType = "appt";
    }
    else if (id == "navDemoAppt") {
      $('#appointmentForm.tab-pane').removeClass("active")
      $('#unavailabilityForm.tab-pane').removeClass("active")
      $('#demoAppointmentForm.tab-pane').addClass("active");
      eventType = "demoAppt";
    } else {
      $('#appointmentForm.tab-pane').removeClass("active")
      $('#unavailabilityForm.tab-pane').addClass("active")
      $('#demoAppointmentForm.tab-pane').removeClass("active")
      eventType = "unavail"
    }
  })

  $('#unavailInstructor').on('change', function (e) {
    $('#unavailAircraft').val(null).selectpicker("refresh")
    $('#unavailSimulator').val(null).selectpicker("refresh")
    $('#unavailRoom').val(null).selectpicker("refresh")
  })

  $('#unavailAircraft').on('change', function (e) {
    $('#unavailInstructor').val(null).selectpicker("refresh")
    $('#unavailSimulator').val(null).selectpicker("refresh")
    $('#unavailRoom').val(null).selectpicker("refresh")
  })

  $('#unavailSimulator').on('change', function (e) {
    $('#unavailAircraft').val(null).selectpicker("refresh")
    $('#unavailInstructor').val(null).selectpicker("refresh")
    $('#unavailRoom').val(null).selectpicker("refresh")
  })

  $('#unavailRoom').on('change', function (e) {
    $('#unavailAircraft').val(null).selectpicker("refresh")
    $('#unavailInstructor').val(null).selectpicker("refresh")
    $('#unavailSimulator').val(null).selectpicker("refresh")
  })

  // navigate calendar to selected date
  $('#btnGo').click(function () {
    $('#dateSelectModal').modal('hide')
    $calendar.fullCalendar('gotoDate', moment($('#datepickercustom').val()).format())
  })

  var showError = function (errors, event) {
    if (errors.filter(s => s.includes("already removed")).length) {
      $('#calendarNewModal').modal('hide')
      $calendar.fullCalendar('refetchEvents')

      $.notify({
        message: event + " already removed please recreate it"
      }, {
        type: "danger",
        placement: { align: "center" }
      })
    } else {
      for (var error of errors) {
        $.notify({
          message: error
        }, {
          type: "danger",
          placement: { align: "center" }
        })
      }
    }
  }

  // collect event data on save and send to server
  $('#btnSave').click(function () {
    console.log("save Button Clicked")

    var buttonPos = $(this).offset();

    $('#loader').css({ top: buttonPos.top + 16.5, left: buttonPos.left - 170 }).show();

    $(this).attr("disabled", true);
    setTimeout(function () {
      $('#btnSave').removeAttr("disabled");
    }, 3000);

    var promise = null;

    if (eventType == "appt") {
      var eventRenter = safeParseInt($('#apptStudent').val());
      var eventInstructor = safeParseInt($('#apptInstructor').val());
      var eventAircraft = safeParseInt($('#apptAircraft').val());
      var eventSimulator = safeParseInt($('#apptSimulator').val());
      var eventRoom = safeParseInt($('#apptRoom').val());


      var eventStart = (moment.utc($('#apptStart').val()).add(-(moment().utcOffset()), 'm')).format()
      var eventEnd = (moment.utc($('#apptEnd').val()).add(-(moment().utcOffset()), 'm')).format()
      var eventNote = $('#apptNote').val()

      var eventData = {
        start_at: eventStart,
        end_at: eventEnd,
        user_id: eventRenter,
        instructor_user_id: eventInstructor,
        aircraft_id: eventAircraft,
        simulator_id: eventSimulator,
        room_id: eventRoom,
        note: eventNote,
        type: "lesson"
      };

      if (appointmentOrUnavailabilityId) {
        promise = $.ajax({
          method: "put",
          url: "/api/appointments/" + appointmentOrUnavailabilityId + addSchoolIdParam('?'),
          data: { data: eventData },
          headers: AUTH_HEADERS
        })
      } else {
        promise = $.post({
          url: "/api/appointments" + addSchoolIdParam('?'),
          data: { data: eventData },
          headers: AUTH_HEADERS
        })
      }
    } else if (eventType == "demoAppt") {
      var payerName = $('#demoApptCustomer').val();

      payerName = (typeof (payerName) === "undefined" || payerName === "" || payerName === " ") ? "Demo Flight" : payerName

      var eventInstructor = safeParseInt($('#demoApptInstructor').val());
      var eventAircraft = safeParseInt($('#demoApptAircraft').val());

      var eventStart = (moment.utc($('#demoApptStart').val()).add(-(moment().utcOffset()), 'm')).format()
      var eventEnd = (moment.utc($('#demoApptEnd').val()).add(-(moment().utcOffset()), 'm')).format()
      var eventNote = $('#demoApptNote').val()

      var eventData = {
        start_at: eventStart,
        end_at: eventEnd,
        user_id: null,
        payer_name: payerName,
        demo: true,
        instructor_user_id: eventInstructor,
        aircraft_id: eventAircraft,
        note: eventNote,
        type: "lesson"
      };

      if (appointmentOrUnavailabilityId) {
        promise = $.ajax({
          method: "put",
          url: "/api/appointments/" + appointmentOrUnavailabilityId + addSchoolIdParam('?'),
          data: { data: eventData },
          headers: AUTH_HEADERS
        })
      } else {
        promise = $.post({
          url: "/api/appointments" + addSchoolIdParam('?'),
          data: { data: eventData },
          headers: AUTH_HEADERS
        })
      }

    } else if (eventType == "unavail") {
      var eventFor = $('#unavailFor').val();
      var eventInstructor = safeParseInt($('#unavailInstructor').val());
      var eventAircraft = safeParseInt($('#unavailAircraft').val());
      var eventSimulator = safeParseInt($('#unavailSimulator').val());
      var eventRoom = safeParseInt($('#unavailRoom').val());

      var eventStart;
      var eventEnd;
      if (eventInstructor){
        eventStart = (moment.utc($('#unavailStart').val()).add(-(moment().utcOffset()), 'm')).format()
        eventEnd = (moment.utc($('#unavailEnd').val()).add(-(moment().utcOffset()), 'm')).format()
      }
      else { //eventAircraft
        eventStart = moment($('#unavailStart').val()).format()
        eventEnd = moment($('#unavailEnd').val()).format()
      }
      var eventNote = $('#unavailNote').val()

      var eventData = {
        start_at: eventStart,
        end_at: eventEnd,
        instructor_user_id: eventInstructor,
        aircraft_id: eventAircraft,
        room_id: eventRoom,
        simulator_id: eventSimulator,
        note: eventNote,
        belongs: eventFor
      };

      var promise;

      if (appointmentOrUnavailabilityId) {
        promise = $.ajax({
          method: "put",
          url: "/api/unavailabilities/" + appointmentOrUnavailabilityId + addSchoolIdParam('?'),
          data: { data: eventData },
          headers: AUTH_HEADERS
        })
      } else {
        promise = $.post({
          url: "/api/unavailabilities" + addSchoolIdParam('?'),
          data: { data: eventData },
          headers: AUTH_HEADERS
        })
      }

      console.log(eventData);
    } else {
      alert('nothing selected');
    }

    if (promise) {
      var event;
      if (eventType == "appt") {
        event = "appointment"
      } else if (eventType == "demoAppt") {
        event = "demo flight appointment"
      } else {
        event = "unavailability"
      }

      promise.then(function () {
        $('#calendarNewModal').modal('hide')
        $calendar.fullCalendar('refetchEvents')

        $.notify({
          message: "Successfully saved " + event
        }, {
          type: "success",
          placement: { align: "center" }
        })

      }).catch(function (e) {
        if (e.responseJSON.human_errors) {
          showError(e.responseJSON.human_errors, event)
        } else {
          $.notify({
            message: "There was an error creating the event"
          }, {
            type: "danger",
            placement: { align: "center" }
          })
        }
        $('#loader').hide();
      })
    }
  });

  $('#btnInvoice').click(function () {
    if (appointmentId) {
      var promise = null;
      var buttonPos = $(this).offset();

      $('#loader').css({ top: buttonPos.top + 16.5, left: buttonPos.left - 160 }).show();

      promise = $.ajax({
        method: "post",
        url: "/api/invoices/from_appointment/" + appointmentId,
        headers: AUTH_HEADERS
      }).catch(function (error) {
        window.location.href = `/billing/invoices/new?appointment_id=${appointmentId}`
      })

      promise.then(function (response) {
        window.location.href = `/billing/invoices/${response.data.id}/edit`
      })
      $('#loader').hide();
    }
  });


  $('#btnDelete').click(function () {
    if (appointmentOrUnavailabilityId) {
      var promise = null;
      var buttonPos = $(this).offset();

      $('#loader').css({ top: buttonPos.top + 16.5, left: buttonPos.left - 90 }).show();

      if (eventType == "appt") {
        promise = $.ajax({
          method: "delete",
          url: "/api/appointments/" + appointmentOrUnavailabilityId + addSchoolIdParam('?'),
          headers: AUTH_HEADERS
        })
      } else if (eventType == "demoAppt") {
        promise = $.ajax({
          method: "delete",
          url: "/api/appointments/" + appointmentOrUnavailabilityId + addSchoolIdParam('?'),
          headers: AUTH_HEADERS
        })
      } else {
        promise = $.ajax({
          method: "delete",
          url: "/api/unavailabilities/" + appointmentOrUnavailabilityId + addSchoolIdParam('?'),
          headers: AUTH_HEADERS
        })
      }

      var event;
      if (eventType == "appt") {
        event = "appointment"
      } else if (eventType == "demoAppt") {
        event = "demo flight appointment"
      } else {
        event = "unavailability"
      }

      promise.then(function () {
        $('#calendarNewModal').modal('hide')
        $calendar.fullCalendar('refetchEvents')

        $.notify({
          message: "Successfully deleted " + event
        }, {
          type: "success",
          placement: { align: "center" }
        })

      }).catch(function (e) {
        if (e.responseJSON.human_errors) {
          showError(e.responseJSON.human_errors, event)
        } else {
          $.notify({
            message: "There was an error deleting the event"
          }, {
            type: "danger",
            placement: { align: "center" }
          })
        }
        $('#loader').hide();
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
    
    // $('#unavailInstructor').val(null).selectpicker("refresh");
    // $('#unavailAircraft').val(null).selectpicker("refresh");
    // $('#unavailSimulator').val(null).selectpicker("refresh");
    // $('#unavailRoom').val(null).selectpicker("refresh");
    // $('#unavailNote').val(null);

    var unavailType = "Instructor";
    // $('#unavailFor').val(unavailType).selectpicker("refresh");
    // displayForUnavailability(unavailType)

    $('#unavailInstructor').val(initialData.instructor_user_id).selectpicker("refresh");
      $('#unavailAircraft').val(initialData.aircraft_id).selectpicker("refresh");
      $('#unavailSimulator').val(initialData.simulator_id).selectpicker("refresh");
      $('#unavailRoom').val(initialData.room_id).selectpicker("refresh");
      $('#unavailNote').val(initialData.note);

      if (initialData.instructor_user_id) {
        unavailType = "Instructor"

      } else if (initialData.aircraft_id) {
        unavailType = "Aircraft"

      } else if (initialData.simulator_id) {
        unavailType = "Simulator"

      } else {
        unavailType = "Room"
      }

      $('#unavailFor').val(unavailType).selectpicker("refresh");
      displayForUnavailability(unavailType)

    if (initialData.type == "unavailability") {
      $('#btnInvoice').hide()
      $('#navUnavail').tab("show")
      
      if (appointmentOrUnavailabilityId) {
        $('#apptTitle').text("Edit Unavailability")
      } else {
        $('#apptTitle').text("Create New")
      }

      $('#unavailInstructor').val(initialData.instructor_user_id).selectpicker("refresh");
      $('#unavailAircraft').val(initialData.aircraft_id).selectpicker("refresh");
      $('#unavailSimulator').val(initialData.simulator_id).selectpicker("refresh");
      $('#unavailRoom').val(initialData.room_id).selectpicker("refresh");
      $('#unavailNote').val(initialData.note);

      if (initialData.instructor_user_id) {
        unavailType = "Instructor"

      } else if (initialData.aircraft_id) {
        unavailType = "Aircraft"

      } else if (initialData.simulator_id) {
        unavailType = "Simulator"

      } else {
        unavailType = "Room"
      }

      $('#unavailFor').val(unavailType).selectpicker("refresh");
      displayForUnavailability(unavailType)
    }
    else if (initialData.type == "demoAppointment"){
      appointmentId = initialData.id;
      if (appointmentId) {
        $('#btnInvoice').show()
      } else {
        $('#btnInvoice').hide()
      }

      $('#navDemoAppt').tab("show")
      if (appointmentOrUnavailabilityId) {
        $('#apptTitle').text("Edit Appointment")
      } else {
        $('#apptTitle').text("Create New")
      }
    } else {
      appointmentId = initialData.id;
      if (appointmentId) {
        $('#btnInvoice').show()
      } else {
        $('#btnInvoice').hide()
      }

      $('#navAppt').tab("show")
      if (appointmentOrUnavailabilityId) {
        $('#apptTitle').text("Edit Appointment")
      } else {
        $('#apptTitle').text("Create New")
      }
    }

    $('#apptStart').val(initialData.start_at.format(displayFormat))
    $('#apptEnd').val(initialData.end_at.format(displayFormat))

    if (initialData.user_name && meta_roles.content == "student") {
      $('#apptStudent').append(new Option(initialData.user_name, initialData.user_id));
      $('#apptStudent').val(initialData.user_id);
      $('#apptStudent').prop("disabled", true).selectpicker("refresh");
      $('#apptStudent').find('option:last').remove();
    } else {
      if (meta_roles.content != "student") { $('#apptStudent').val(initialData.user_id); }

      $('#apptStudent').prop("disabled", false).selectpicker("refresh");
    }
    
    $('#apptInstructor').val(initialData.instructor_user_id).selectpicker("refresh");
    $('#apptAircraft').val(initialData.aircraft_id).selectpicker("refresh");
    $('#apptSimulator').val(initialData.simulator_id).selectpicker("refresh");
    $('#apptRoom').val(initialData.room_id).selectpicker("refresh");
    $('#apptNote').val(initialData.note);

    $('#unavailStart').val(initialData.start_at.format(displayFormat))
    $('#unavailEnd').val(initialData.end_at.format(displayFormat))

    // var element = document.getElementById('unavailRoom');
    // var event = new Event('change');
    // element.dispatchEvent(event);

    $('#demoApptStart').val(initialData.start_at.format(displayFormat))
    $('#demoApptEnd').val(initialData.end_at.format(displayFormat))

    if (initialData.user_name && meta_roles.content == "student") {
      $('#demoApptStudent').append(new Option(initialData.user_name, initialData.user_id));
      $('#demoApptStudent').val(initialData.user_id);
      $('#demoApptStudent').prop("disabled", true).selectpicker("refresh");
      $('#demoApptStudent').find('option:last').remove();
    } else {
      if (meta_roles.content != "student") { $('#demoApptStudent').val(initialData.user_id); }

      $('#demoApptStudent').prop("disabled", false).selectpicker("refresh");
    }

    $('#demoApptInstructor').val(initialData.instructor_user_id).selectpicker("refresh");
    $('#demoApptAircraft').val(initialData.aircraft_id).selectpicker("refresh");
    $('#demoApptNote').val(initialData.note);
    $('#demoApptCustomer').val(initialData.payer_name);

    $('#calendarNewModal').modal();
  };

  function fsmCalendar(instructors, aircrafts, simulators, rooms, current_user) {
   
    var resources = instructors.map(function (instructor) {
      return {
        id: "instructor:" + instructor.id,
        type: "Instructors",
        title: fullName(instructor),
        current_user: current_user
      }
    })

    resources = resources.concat(aircrafts.map(function (aircraft) {
      return {
        id: "aircraft:" + aircraft.id,
        type: "Aircrafts",
        title: aircraft.make + " " + aircraft.tail_number, 
        current_user: current_user
      }
    }))

    resources = resources.concat(simulators.map(function (simulator) {
      return {
        id: "simulator:" + simulator.id,
        type: "Simulators",
        title: simulator.make + " " + simulator.tail_number, 
        current_user: current_user
      }
    }))

    resources = resources.concat(rooms.map(function (room) {
      return {
        id: "room:" + room.id,
        type: "Rooms",
        title: room.location, 
        current_user: current_user
      }
    }))

    var today = new Date();
    var y = today.getFullYear();
    var m = today.getMonth();
    var d = today.getDate();

    $calendar.fullCalendar({
      viewRender: function (view, element) { },
      header: {
        left: 'title,chooseDateButton',
        center: 'timelineDay,timelineWeek,timelineMonth',
        right: 'prev,next,today,customDate'
      },
      customButtons: {
        customDate: {
          text: 'Select Date',
          click: function () {
            $('#dateSelectModal').modal();
          }
        }
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

      select: function (start, end, notSure, notSure2, resource) {
        var instructorId = null;
        var aircraftId = null;
        var simulatorId = null;
        var roomId = null;

        if (resource) {
          var split = resource.id.split(":")
          var type = split[0]
          var id = parseInt(split[1])

          if (type == "instructor") {
            instructorId = id
          } else if (type == "aircraft") {
            aircraftId = id
          } else if (type == "simulator") {
            simulatorId = id
          } else if (type == "room") {
            roomId = id
          }
        }

        var eventType = "appt"; // setting default event type to appt
        var eventData;
        var thatsAllDay = false;

        var params = {
          start_at: start,
          end_at: moment(start).add(1, 'hours'),
          instructor_user_id: instructorId,
          aircraft_id: aircraftId,
          simulator_id: simulatorId,
          room_id: roomId
        }

        if (resource.current_user && resource.current_user.roles.length == 1 && resource.current_user.roles[0] === "student") {
          params.user_name = fullName(resource.current_user)
          params.user_id = resource.current_user.id
        }

        openAppointmentModal(params)

      },
      editable: true,
      eventClick: function (calEvent, jsEvent, view) {

        if (calEvent.unavailability) {
          var instructor_user_id = null;
          if (calEvent.unavailability.instructor_user) {
            instructor_user_id = calEvent.unavailability.instructor_user.id
          }

          var aircraft_id = null;
          if (calEvent.unavailability.aircraft) {
            aircraft_id = calEvent.unavailability.aircraft.id
          }

          var simulator_id = calEvent.unavailability.simulator && calEvent.unavailability.simulator.id
          var room_id = calEvent.unavailability.room && calEvent.unavailability.room.id

          openAppointmentModal({
            type: "unavailability",
            start_at: moment.utc(calEvent.unavailability.start_at).add(+(moment().utcOffset()), 'm'),
            end_at: moment.utc(calEvent.unavailability.end_at).add(+(moment().utcOffset()), 'm'),
            instructor_user_id: instructor_user_id,
            aircraft_id: aircraft_id,
            simulator_id: simulator_id,
            room_id: room_id,
            note: calEvent.unavailability.note,
            id: calEvent.unavailability.id
          })
          return;
        } else if (calEvent.appointment.demo) {
          var appointment = calEvent.appointment
          var instructor_user_id = null;
          if (appointment.instructor_user) {
            instructor_user_id = appointment.instructor_user.id
          }
          
          var aircraft_id = null;
          
          if (appointment.aircraft) {
            aircraft_id = appointment.aircraft.id
          }

          if( appointment.status == "paid") {
            alert("This appointment has been successfully paid!");
          }

          openAppointmentModal({
            type: "demoAppointment",
            start_at: moment.utc(appointment.start_at).add(+(moment().utcOffset()), 'm'),
            end_at: moment.utc(appointment.end_at).add(+(moment().utcOffset()), 'm'),
            instructor_user_id: instructor_user_id,
            aircraft_id: aircraft_id,
            note: appointment.note,
            demo: appointment.demo,
            payer_name: payerTitle(appointment),
            id: appointment.id
          })
        } else if (calEvent.appointment) {
          var appointment = calEvent.appointment
          var instructor_user_id = null;
          if (appointment.instructor_user) {
            instructor_user_id = appointment.instructor_user.id
          }

          var aircraft_id = null;
          var aircraft_id = null;
          var simulator_id = null;
          var room_id = appointment.room && appointment.room.id;

          if (appointment.aircraft) {
            aircraft_id = appointment.aircraft.id
          }

          if (appointment.simulator){
            simulator_id = appointment.simulator.id;
          }
          
          if( appointment.status == "paid") {
            alert("This appointment has been successfully paid!");
          }
          
          openAppointmentModal({
            start_at: moment.utc(appointment.start_at).add(+(moment().utcOffset()), 'm'),
            end_at: moment.utc(appointment.end_at).add(+(moment().utcOffset()), 'm'),
            instructor_user_id: instructor_user_id,
            aircraft_id: aircraft_id,
            simulator_id: simulator_id,
            room_id: room_id,
            note: appointment.note,
            user_id: appointment.user ? appointment.user.id : null,
            user_name: appointmentTitle(appointment),
            id: appointment.id
          })
        }

      },


      eventLimit: true, // allow "more" link when too many events

      // color classes: [ event-blue | event-azure | event-green | event-orange | event-red ]
      events: function (start, end, timezone, callback) {
        var startStr = (moment(start).add(-(moment().utcOffset()), 'm')).toISOString();
        var endStr = (moment(end).add(-(moment().utcOffset()), 'm')).toISOString();

        var paramStr = addSchoolIdParam('', '&') + "from=" + startStr + "&to=" + endStr;

        var appointmentsPromise = $.get({
          url: "/api/appointments?" + paramStr,
          headers: AUTH_HEADERS
        });

        var unavailabilityPromise = $.get({
          url: "/api/unavailabilities?" + paramStr,
          headers: AUTH_HEADERS
        });

        Promise.all([appointmentsPromise, unavailabilityPromise]).then(function (resp) {
          var appointments = resp[0].data.map(function (appointment) {
            var resourceIds = []

            if (appointment.instructor_user) {
              resourceIds.push("instructor:" + appointment.instructor_user.id)
            }

            if (appointment.aircraft) {
                resourceIds.push("aircraft:" + appointment.aircraft.id)
            }

            if (appointment.simulator) {
              resourceIds.push("simulator:" + appointment.simulator.id)
            }

            if (appointment.room) {
              resourceIds.push("room:" + appointment.room.id)
            }

            return {
              title: appointmentTitle(appointment),
              start: moment.utc(appointment.start_at).add(+(moment().utcOffset()), 'm'),
              end: moment.utc(appointment.end_at).add(+(moment().utcOffset()), 'm'),
              id: "appointment:" + appointment.id,
              appointment: appointment,
              resourceIds: resourceIds,
              className: 'event-blue'
            }
          })

          var unavailabilities = resp[1].data.map(function (unavailability) {
            var resourceIds = []

            if (unavailability.instructor_user) {
              resourceIds.push("instructor:" + unavailability.instructor_user.id)
            }

            if (unavailability.aircraft) {
              resourceIds.push("aircraft:" + unavailability.aircraft.id)
            }

            if (unavailability.simulator) {
              resourceIds.push("simulator:" + unavailability.simulator.id)
            }

            if (unavailability.room) {
              resourceIds.push("room:" + unavailability.room.id)
            }

            return {
              title: "Unavailable",
              start: moment.utc(unavailability.start_at).add(+(moment().utcOffset()), 'm'),
              end: moment.utc(unavailability.end_at).add(+(moment().utcOffset()), 'm'),
              id: "unavailability:" + unavailability.id,
              unavailability: unavailability,
              resourceIds: resourceIds,
              className: 'event-default'
            }
          })
          $('#loader').hide();
          callback(appointments.concat(unavailabilities))
        })
      }
    });
  }

  var users = $.get({ url: "/api/users?form=directory" + addSchoolIdParam('&'), headers: AUTH_HEADERS })
  var aircrafts = $.get({ url: "/api/aircrafts" + addSchoolIdParam('?'), headers: AUTH_HEADERS })
  var rooms = $.get({url: "/api/rooms" + addSchoolIdParam('?'), headers: AUTH_HEADERS})

  var current_user = $.get({ url: "/api/user_info", headers: AUTH_HEADERS })

  Promise.all([users, aircrafts, rooms, current_user]).then(function (values) {
    var instructors = values[0].data.filter(function (user) {
      return user.roles.indexOf("instructor") != -1
    });

    const aircrafts = values[1].data.filter(function(item) {return !item.simulator})
    const simulators = values[1].data.filter(function(item) {return item.simulator})

    fsmCalendar(instructors, aircrafts, simulators, values[2].data, values[3]);
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
    $('#datepickercustom').datetimepicker({
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
      },
      format: 'L'
    });
  }
  initDateTimePicker();
});
