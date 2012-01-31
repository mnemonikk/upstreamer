$(function() {
  // automatically submit the upload form when a file is selected
  $("#fileInput").change(function() {
    upload.start();
    $(this).parents("form").submit();
  });
});

var upload = (function() {
  var upload_id;
  return {
    init: function(options) {
      upload_id = options.upload_id;
    },
    start: function() {
      $("#fileInput").hide();
      $(".progress-bar").show();
      $("iframe[name=progress]").attr("src", "/progress?" + encodeURIComponent(upload_id));
    },
    progress: function(pos, length) {
      $(".progress-bar span").css("width", parseInt(pos / length * 100) + "%");
    },
    finish: function(filename, url) {
      // TODO: proper quoting
      $("#success").html("Here's your file <a href=\"" + url + "\">" + filename + "</a>").show();
    }
  };
})();
