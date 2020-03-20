$(document).ready(function() {
  function initDataTable(){
    $('#datatable').DataTable({
      "paging": false,
      "lengthMenu": [
        [10, 25, 50, -1],
        [10, 25, 50, "All"]
      ],
      responsive: true,
      language: {
        search: "_INPUT_",
        searchPlaceholder: "Search records",
      }
    });
  }

  if (document.getElementById("initDataTable")) {
    initDataTable();
  }

  function initDateTimePicker() {
    $('.datetimepickerstart').datetimepicker({
      // debug: true,
      format: "MM-DD-YYYY",
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
      format: "MM-DD-YYYY",
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
      var inputEndDate = $('.datetimepickerend').data("DateTimePicker");

      inputEndDate.minDate(e.date);

      if (inputEndDate.date() < e.date) {
        inputEndDate.date(e.date)
      }
    });
    $(".datetimepickerend").on("dp.change", function (e) {
      $('.datetimepickerstart').data("DateTimePicker").maxDate(e.date);
    });
  }
  initDateTimePicker();

  $('#btnPrint').click(function () {
    var htmlToPrint = '' +
      '<style type="text/css">' +
      'table th, table td {' +
      'border:1px solid #000;' +
      'padding:0.5em;' +
      '}' +
      'a {' +
      'text-decoration:none;' +
      '}' +
      '</style>';
    $("#datatable_filter").remove();
    window.frames["print_frame"].document.body.innerHTML = htmlToPrint + $("#tableWrapper").html();
    window.frames["print_frame"].window.focus();
    window.frames["print_frame"].window.print();
  });

  "use strict";

  function _instanceof(left, right) {
    if (right != null && typeof Symbol !== "undefined" && right[Symbol.hasInstance]) {
      return !!right[Symbol.hasInstance](left);
    } else {
      return left instanceof right;
    }
  }

  function _classCallCheck(instance, Constructor) {
    if (!_instanceof(instance, Constructor)) {
      throw new TypeError("Cannot call a class as a function");
    }
  }

  function _defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor)
        descriptor.writable = true;

      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  function _createClass(Constructor, protoProps, staticProps) {
    if (protoProps)
      _defineProperties(Constructor.prototype, protoProps);
    if (staticProps)
      _defineProperties(Constructor, staticProps);

    return Constructor;
  }

  $('#btnCsv').click(function () {
    var dataTable = document.getElementById("datatable");
    var exporter = new TableCSVExporter(dataTable);
    var csvOutput = exporter.convertToCSV();
    var csvBlob = new Blob([csvOutput], { type: "text/csv" });
    var blobUrl = URL.createObjectURL(csvBlob);
    var anchorElement = document.createElement("a");

    anchorElement.href = blobUrl;
    anchorElement.download = "table-export.csv";
    anchorElement.click();

    setTimeout(function () {
      URL.revokeObjectURL(blobUrl);
    }, 500);
  });

  var TableCSVExporter = /*#__PURE__*/function () {
    function TableCSVExporter(table) {
      var includeHeaders = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;

      _classCallCheck(this, TableCSVExporter);

      this.table = table;
      this.rows = Array.from(table.querySelectorAll("tr"));

      if (!includeHeaders && this.rows[0].querySelectorAll("th").length) {
        this.rows.shift();
      }
    }

    _createClass(TableCSVExporter, [{
      key: "convertToCSV",
      value: function convertToCSV() {
        var lines = [];

        var numCols = this._findLongestRowLength();

        var _iteratorNormalCompletion = true;
        var _didIteratorError = false;
        var _iteratorError = undefined;

        try {
          for (var _iterator = this.rows[Symbol.iterator](), _step;
            !(_iteratorNormalCompletion = (_step = _iterator.next()).done);
            _iteratorNormalCompletion = true) {

            var row = _step.value;
            var line = "";

            for (var i = 0; i < numCols; i++) {
              if (row.children[i] !== undefined) {
                line += TableCSVExporter.parseCell(row.children[i]);
              }

              line += i !== numCols - 1 ? "," : "";
            }

            lines.push(line);
          }
        } catch (err) {
          _didIteratorError = true;
          _iteratorError = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion && _iterator.return != null) {
              _iterator.return();
            }
          } finally {
            if (_didIteratorError) {
              throw _iteratorError;
            }
          }
        }

        return lines.join("\n");
      }
    }, {
      key: "_findLongestRowLength",
      value: function _findLongestRowLength() {
        return this.rows.reduce(function (l, row) {
          return row.childElementCount > l ? row.childElementCount : l;
        }, 0);
      }
    }], [{
      key: "parseCell",
      value: function parseCell(tableCell) {
        var parsedValue = tableCell.textContent;

        parsedValue = parsedValue.replace(/"/g, "\"\"");
        parsedValue = /[",\n]/.test(parsedValue) ? "\"".concat(parsedValue, "\"") : parsedValue;
        return parsedValue;
      }
    }]);

    return TableCSVExporter;
  }();
});
