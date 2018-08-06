/* global $, swal */

$(document).ready(function() {
  
  
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
          	
          	var startTime = start.format('MM DD YY, h:mm a');
          	var eventType="appt"; // setting default event type to appt
          	var eventData;
          	var style;
          	var thatsAllDay = false;
            
            $('#calendarNewModal').modal();
            
            // change event type based on user choice
            $('#navAppt').click(function(){
              eventType="appt";  
            });
            $('#navUnavail').click(function(){
              eventType="unavail";  
            });
            
            // collect event data on save and return to calendar
            $('#btnSave').click(function(){
              
              if(eventType=="appt"){
                var event_student = $('#apptStudent').val();
                var event_instructor = $('#apptInstructor').val();
                var event_aircraft = $('#apptAircraft').val();
                
                var event_title = event_student + ", " + event_instructor + ", " + event_aircraft;
    						var event_start = $('#apptStart').val();
    						var event_end = $('#apptEnd').val();
    						style = 'event-blue';
    						thatsAllDay = false;
    
                if (event_title){
        					eventData = {
        						title: event_title,
        						start: event_start,
        						end: event_end,
        						student: event_student,
        						instructor: event_instructor,
        						aircraft: event_aircraft
        				  };
        				  console.log(eventData);
        					$calendar.fullCalendar('renderEvent', eventData, true);
                }
                
                $calendar.fullCalendar('unselect');
              }else if (eventType=="unavail"){
                style = 'event-default';
                var titleDescription = ' — Unavailable';
                
                if (unavailType == 'Aircraft'){
                  var event_title = $('#unavailAircraft').val() + titleDescription;
                }else {
                  var event_title = $('#unavailInstructor').val() + titleDescription;  
                }
                
    						var event_start = $('#unavailStart').val();
    						var event_end = $('#unavailEnd').val();
    						
    						if ($('#unavailAllDay').prop('checked')){
    						  thatsAllDay = true;
    						}else{
    						  thatsAllDay = false;  
    						}
    
                if (event_title){
        					eventData = {
        						title: event_title,
        						start: event_start,
        						end: event_end,
        						allDay: thatsAllDay,
                    className: 'event-default'
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
            console.log(calEvent);
            $('#editApptModal').modal();
            $('#editApptModal').on('shown.bs.modal',function(){
              var event_student = calEvent.student;
              var event_instructor = calEvent.instructor;
              var event_aircraft = calEvent.aircraft;
  						var event_start = calEvent.start.format('MM/DD/YYYY h:mm A');
  						var event_end = calEvent.end.format('MM/DD/YYYY h:mm A');
  						
  						$('#editApptStart').val(event_start);
  						$('#editApptEnd').val(event_end);
  						$('#editApptAircraft').val(event_aircraft).selectpicker("refresh");
  						$('#editApptInstructor').val(event_instructor).selectpicker("refresh");
  						$('#editApptStudent').val(event_student).selectpicker("refresh");
  						
              
            });
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
					title: 'Herman Blume, Max Fischer, Archer N70432',
					start: new Date(y, m, d-1, 10, 30),
					end: new Date(y, m, d-1, 12, 30),
					allDay: false,
					className: 'event-blue',
					student: 'Herman Blume',
					instructor: 'Max Fischer',
					aircraft: 'Archer N70432'
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
					title: 'Peter Flynn, Randon Russell, Archer N70432',
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


    // var mySelect = '<select class="selectpicker" data-size="7" data-live-search="true" data-style="btn btn-default btn-round btn-simple" title="Instructor">' +
    //   '<option>None</option>' +
    //   '<option value="2">Herman Blume</option>' +
    //   '<option value="3">Max Fischer</option>' +
    //   '<option value="3">Jerry Jones</option>' +
    //   '<option value="3">Rosemary Cross</option>' +
    // '</select>';




  });

