require File.expand_path(File.dirname(__FILE__)) + "/../app.rb"
require "test/unit"
require "rack/test"

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    # just testing that the starting page renders without errors
    get "/"
  end

  def test_upload
    post "/upload", "file" => Rack::Test::UploadedFile.new("test/fixtures/bass.jpg", "image/jpeg")
  end

  def test_progress
    upload_id = "1234"
    positions = [0, 20, 50]

    writer = UploadMiddleware.pipe_writer_for(upload_id)
    positions.each do |pos|
      writer.puts "[#{pos}, 50]"
    end
    writer.close

    get "/progress?#{upload_id}"

    positions.each do |pos|
      assert last_response.body.include?(
        %Q(<script type="text/javascript">parent.upload.progress(#{pos}, 50);</script>)),
        "For every position we reported via the pipe writer we should have a script statement in the response"
    end
  end

  def test_submit
    # just testing that the submit page renders without errors
    post "/submit", :original_filename => "foo.mp3", :url => "/path/to/foo.mp3", :description => "This is the description."
  end
end
