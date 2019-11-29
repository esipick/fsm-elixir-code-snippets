$(document).ready(function() {
  function initDateTimePicker() {
    $('.datetimepickerstart').datetimepicker({
        // debug: true,
        format: 'MM-DD-YYYY',
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
        format: 'MM-DD-YYYY',
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
});
