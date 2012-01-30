$(function() {
  // automatically submit the upload form when a file is selected
  $("#fileInput").change(function() {
    upload.start();
    $(this).parents("form").submit();
  });
});

var upload = (function() {
  return {
    start: function() {
      $("#fileInput").hide();
      $(".progress-bar").show();
      $("iframe[name=progress]").attr("src", "/progress");
    },
    progress: function(pos, length) {
      $(".progress-bar span").css("width", parseInt(pos / length * 100) + "%");
    }
  };
})();
