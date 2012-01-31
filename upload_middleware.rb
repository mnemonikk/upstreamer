class UploadMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] =~ %r(^/upload)
      @env    = env
      @pos    = 0
      @length = env["CONTENT_LENGTH"]
      @length = @length.to_i if @length

      _, @pipe = pipes_for(env["QUERY_STRING"])
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
      _inc(retval.size) if retval
    end
  end

  def read(*args)
    @input.read(*args).tap do |retval|
      _inc(retval.size) if retval
    end
  end

  def each
    @input.each do |chunk|
      yield chunk
    end
  end

  def _inc(size)
    @pos += size
    @pipe.puts JSON.dump([@pos, @length])
    @pipe.close if @pos == @length
  end
end
