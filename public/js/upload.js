var upload = (function() {
  var upload_id;
  var started  = false;
  var finished = false;

  var check_description_form = function() {
    if (!started) {
      alert("Please upload a file first.");
      return false;
    } else if (!finished) {
      alert("Please wait for the upload to finish.");
      return false;
    }
    return true;
  }

  $(function() {
    // automatically submit the upload form when a file is selected
    $("#file").change(function() {
      upload.start();
      $(this).parents("form").submit();
    });

    // Posting the description form will cause the user to leave the
    // page. This doesn't make sense when there's no file uploaded
    // yet, and an upload in progress would be aborted.
    $("#description_form").submit(check_description_form);
  });

  return {
    init: function(options) {
      upload_id = options.upload_id;
    },
    
    start: function() {
      started = true;
      $("#file").hide();
      $(".progress-bar").show();
      $("iframe[name=progress]").attr("src", "/progress?" + encodeURIComponent(upload_id));
    },
    
    progress: function(pos, length) {
      $(".progress-bar span").css("width", parseInt(pos / length * 100) + "%");
    },
    
    finish: function(filename, url) {
      finished = true;
      var link = $("<a></a>").attr("href", url).text(filename)
      $("#success").html("Here's your file ").append(link).show();
      $(".progress-bar").removeClass("animated");
      $("form .control-group").first().addClass("success");

      $("#description_form input[name=original_filename]").attr("value", filename);
      $("#description_form input[name=url]").attr("value", url);
    }
  };
})();
