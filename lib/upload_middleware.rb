require "json"
require "cgi"
require "rack"

class UploadMiddleware
  class Input
    UPDATE_INTERVAL = 1 # seconds

    attr_reader :input, :logger

    def initialize(options)
      @input, @upload_id, @pipe, @length, @logger =
        options.values_at(:input, :upload_id, :pipe, :length, :logger)
      @length = @length.to_i if @length
      @pos = @seen = 0
      @updated_at = Time.now
    end

    def each
      @input.each { |chunk| yield chunk }
    end

    def size; @input.size; end

    def rewind
      @pos = 0
      @input.rewind
    end

    def gets
      @input.gets.tap do |retval|
        _chunk_received(retval.size) if retval
      end
    end

    def read(*args)
      @input.read(*args).tap do |retval|
        _chunk_received(retval.size) if retval
      end
    end

    def _chunk_received(size)
      return if size == 0
      return if @pipe.closed?

      @pos += size

      return if @seen > @pos
      @seen = @pos

      return _finish if @length && @pos >= @length

      now = Time.now
      return if (now - @updated_at) < UPDATE_INTERVAL
      @updated_at = now

      @pipe.puts JSON.dump([@pos, @length]) + "\n"
    rescue Errno::EPIPE
      _cleanup
    end

    def _finish
      @pipe.puts JSON.dump([@length, @length]) + "\n"
      _cleanup
    end

    def _cleanup
      @pipe.close
      UploadMiddleware.forget_pipes_for(@upload_id)
    end
  end

  @@pipes_hash  ||= {}
  @@pipes_mutex ||= Mutex.new

  attr_accessor :input

  def self.pipes_for(upload_id)
    @@pipes_mutex.synchronize do
      @@pipes_hash[upload_id] ||= IO.pipe
    end
  end

  def self.pipe_reader_for(upload_id)
    pipes_for(upload_id)[0]
  end

  def self.pipe_writer_for(upload_id)
    pipes_for(upload_id)[1]
  end

  def self.forget_pipes_for(upload_id)
    @@pipes_mutex.synchronize do
      @@pipes_hash.delete(upload_id)
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] == "/upload"
      params = Rack::Request.new(env).GET
      upload_id = params["upload_id"]
      env["rack.input"] = @input =
        Input.new(
          :input     => env["rack.input"],
          :logger    => env["rack.logger"],
          :length    => env["CONTENT_LENGTH"],
          :upload_id => upload_id,
          :pipe      => UploadMiddleware.pipe_writer_for(upload_id))
    end
    @app.call(env)
  end

end
