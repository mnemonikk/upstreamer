require "json"

class UploadMiddleware
  @@pipes_hash  ||= {}
  @@pipes_mutex ||= Mutex.new

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
      @env    = env
      @pos    = 0
      @length = env["CONTENT_LENGTH"]
      @length = @length.to_i if @length

      @upload_id = CGI.parse(env["QUERY_STRING"])["upload_id"].first
      @pipe = UploadMiddleware.pipe_writer_for(@upload_id)

      @input, env["rack.input"] = env["rack.input"], self
    end
    @app.call(env)
  end

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

  def each
    @input.each do |chunk|
      yield chunk
    end
  end

  def _chunk_received(size)
    return if size == 0
    @pos += size
    @pipe.puts JSON.dump([@pos, @length])
    if @pos == @length
      @pipe.close
      UploadMiddleware.forget_pipes_for(@upload_id)
    end
  end
end
