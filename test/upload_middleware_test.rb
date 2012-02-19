require File.expand_path(File.dirname(__FILE__)) + "/../lib/upload_middleware.rb"

require "test/unit"
require "mocha"
require "yaml" # for StringIO
require "timecop"
require "logger"

class UploadMiddlewareTest < Test::Unit::TestCase
  def test_input_wrapper
    data = "abc\n" * (1024 * 10)
    upload_id = "abc123"
    data_input = StringIO.new(data)

    env =
      {"PATH_INFO"      => "/upload",
       "rack.input"     => data_input,
       "rack.logger"    => Logger.new(STDOUT),
       "QUERY_STRING"   => "upload_id=#{upload_id}",
       "CONTENT_LENGTH" => data.size }

    app = mock()
    app.expects(:call).with(env)

    middleware = UploadMiddleware.new(app)
    middleware.call(env)

    reader = UploadMiddleware.pipe_reader_for(upload_id)

    # read just one line
    Timecop.travel(Time.now + 2)
    assert_equal "abc\n", middleware.input.gets
    assert_equal "[4,#{data.size}]\n", reader.gets

    # read the rest of the data
    Timecop.travel(Time.now + 2)
    assert_equal data.size - 4, middleware.input.read(data.size).size
    assert_equal "[#{data.size},#{data.size}]\n", reader.gets

    assert_not_equal reader, UploadMiddleware.pipe_reader_for(upload_id),
      "We should get a fresh pipe reader"

    # trying to read past the end of the file should not cause an
    # error
    middleware.input.read
  end
end
