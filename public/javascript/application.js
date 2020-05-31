$(function() {
  $('form.delete').on('submit', function(event) {
    event.preventDefault();
    event.stopPropagation();
    if (confirm('Really want to delete this?')) {
      // this.submit();
      var form = $(this);
      var request = $.ajax({
        url: form.attr('action'),
        method: form.attr('method')
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status === 204) {
          var name = form.parent('li').children('h3')[0].innerText;
          form.parent("li").remove();
          $('div.success').css('display', '');
          $('div.success p')[0].textContent = 'Todo "' + name + '" deleted.';
        } else if (jqXHR.status === 200) {
          document.location = data;
        }
      });
    }
  });
});

// $(function() {

//   $("form.delete").submit(function(event) {
//     event.preventDefault();
//     event.stopPropagation();

//     var ok = confirm("Are you sure? This cannot be undone!");
//     if (ok) {
//       var form = $(this);

//       var request = $.ajax({
//         url: form.attr("action"),
//         method: form.attr("method")
//       });

//       request.done(function(data, textStatus, jqXHR) {
//         if (jqXHR.status === 204) {
//           form.parent("li").remove();
//         } else if (jqXHR.status === 200) {
//           document.location = data;
//         }
//       });
//     }
//   });

// });