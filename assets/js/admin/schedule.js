console.log("working");

/* global $, swal */

$(document).ready(function() {

    function fsmCalendar(){
        var $calendar = $('#fullCalendar');

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
						center: 'month,agendaWeek,agendaDay,listWeek',
						right: 'prev,next,today'
					},
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

					select: function(start, end) {
          	// on select we show the Sweet Alert modal with an input and initialize the datetimepicker
          	var startTime = start.format('MM DD YY, h:mm a');

            $('#calendarModal').modal();
            var eventType="appt";
            
            $('#navAppt').click(function(){
              eventType="appt";  
            });
            $('#navUnavail').click(function(){
              eventType="unavail";  
            });
            
            $('#btnSave').click(function(){
              var eventData;
              
              if(eventType=="appt"){
                console.log('appointment');
                var event_title = $('#apptStudent').val() + ", " + $('#apptInstructor').val() + ", " + $('#apptAircraft').val();
    						var event_start = $('#apptStart').val();
    						var event_end = $('#apptEnd').val();
    
                if (event_title){
        					eventData = {
        						title: event_title,
        						start: event_start,
        						end: event_end
        				  };
        				  console.log(eventData);
        					$calendar.fullCalendar('renderEvent', eventData, true);
                }
                
                $calendar.fullCalendar('unselect');
              }else if (eventType=="unavail"){
                console.log('unavailability');
                var event_title = $('#unavailInstructor').val();
    						var event_start = $('#unavailStart').val();
    						var event_end = $('#unavailEnd').val();
    
                if (event_title){
        					eventData = {
        						title: event_title,
        						start: event_start,
        						end: event_end
        				  };
        				  console.log(eventData);
        					$calendar.fullCalendar('renderEvent', eventData, true);
                }
                
                $calendar.fullCalendar('unselect');
              }else{
                alert('nothing selected');
              }
              
            });
            
  			  },
    			editable: true,
    			eventClick: function(calEvent, jsEvent, view){
    			  // the following runs when an existing event is clicked
    			  console.log('Title: ' + calEvent.title);
    			  console.log('Start: ' + calEvent.start);
    			  console.log('End: ' + calEvent.end);
            console.log("Called eventClick")
            console.log(calEvent)

  					swal({
      				title: 'New Appointment',
      				html: '<div class="row"><label class="col-md-3 col-form-label">Start Time</label><div class="col-md-9"><div class="form-group"><input id="input-start" type="text" class="form-control datetimepickerstart" placeholder="Start Time" value="'+calEvent.start+'"></div></div></div>' +
      							'<div class="row"><label class="col-md-3 col-form-label">End Time</label><div class="col-md-9"><div class="form-group"><input id="input-end" type="text" class="form-control datetimepickerend" placeholder="End Time" value=""></div></div></div>' +
      							'<div class="row"><label class="col-md-3 col-form-label">Student</label><div class="col-md-9"><div class="form-group">' +
      							  '<select class="selectpicker" data-size="7" data-style="btn btn-primary btn-round" title="Single Select">' +
                          '<option disabled selected>Single Option</option>' +
                          '<option value="2">Foobar</option>' +
                          '<option value="3">Is great</option>' +
                        '</select>' +
      							'</div></div></div>' +
      							'<div class="row"><label class="col-md-3 col-form-label">Instructor</label><div class="col-md-9"><div class="form-group"><input id="input-instructor" type="text" class="form-control" placeholder="Instructor"></div></div></div>' +
      							'<div class="row"><label class="col-md-3 col-form-label">Aircraft</label><div class="col-md-9"><div class="form-group"><input id="input-aircraft" type="text" class="form-control" placeholder="Aircraft"></div></div></div>'
      							,
      				showCancelButton: true,
              confirmButtonClass: 'btn btn-primary',
              cancelButtonClass: 'btn btn-default',
              confirmButtonText: 'Save',
              buttonsStyling: false
            }).then(function(result) {
              var eventData;
              var event_title = $('#input-student').val() + ", " + $('#input-instructor').val() + ", " + $('#input-aircraft').val();
  						event_start = $('#input-start').val();
  						event_end = $('#input-end').val();

              if (event_title) {
      					eventData = {
      						title: event_title,
      						start: event_start,
      						end: event_end
      					};
      					$calendar.fullCalendar('renderEvent', eventData, true); // stick? = true
      				}
      				$calendar.fullCalendar('unselect');

            });
            initDateTimePicker();
    			},
    			eventLimit: true, // allow "more" link when too many events


            // color classes: [ event-blue | event-azure | event-green | event-orange | event-red ]
            events: [
				{
					title: 'Peter Flyn — Unavailable',
					start: new Date(y, m, d),
					end: new Date(y, m, d+12, 14, 0),
					allDay: true,
                    className: 'event-default'
				},
				{
					title: 'Herman Blume, Randon Russell, Archer N70432',
					start: new Date(y, m, d-1, 10, 30),
					allDay: false,
					className: 'event-blue'
				},
				{
					title: 'Rosemary Cross, Randon Russell, Archer N70432',
					start: new Date(y, m, d+7, 12, 0),
					end: new Date(y, m, d+7, 14, 0),
					allDay: false,
					className: 'event-blue'
				},
				{
					title: 'Max Fischer, Randon Russell, Archer N70432',
					start: new Date(y, m, d+7, 12, 0),
					end: new Date(y, m, d+7, 14, 0),
					allDay: false,
					className: 'event-blue'
				},
				{
					title: 'Herman Blume, Randon Russell, Archer N70432',
					start: new Date(y, m, d+7, 12, 0),
					end: new Date(y, m, d+7, 14, 0),
					allDay: false,
					className: 'event-blue'
				},
				{
					title: 'Nud-pro Launch',
					start: new Date(y, m, d-2, 12, 0),
					allDay: true,
					className: 'event-blue'
				},
				{
					title: 'Something that lasts a few days',
					start: new Date(y, m, d+1, 19, 0),
					end: new Date(y, m, d+3, 22, 30),
					allDay: false,
                    className: 'event-blue'
				},
				{
					title: 'Click to URL',
					start: new Date(y, m, 21),
					end: new Date(y, m, 22),
					url: '/admin/users/3',
					className: 'event-blue'
				}
			]
		});
    }
    fsmCalendar();




    function initDateTimePicker() {
      $('.datetimepickerstart').datetimepicker({
      		// debug: true,
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


    var mySelect = '<select class="selectpicker" data-size="7" data-live-search="true" data-style="btn btn-default btn-round btn-simple" title="Instructor">' +
      '<option>None</option>' +
      '<option value="2">Herman Blume</option>' +
      '<option value="3">Max Fischer</option>' +
      '<option value="3">Jerry Jones</option>' +
      '<option value="3">Rosemary Cross</option>' +
    '</select>';


  });

