$(document).ready(function() {
  // sets the reports nav item to active
  $("a[href='/admin/reports']").parents('li').addClass('active');


  $('#datatable').hide();
  $('#btnSubmit').click(function(){
    $('#datatable').show();
    initDataTable();
  });

  function initDataTable(){
    $('#datatable').DataTable({
      "pagingType": "full_numbers",
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
});
