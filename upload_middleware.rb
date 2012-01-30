class UploadMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @env    = env
    @pos    = 0
    @length = env["CONTENT_LENGTH"]
    @length = @length.to_i if @length

    # env["rack.logger"].info "UploadMiddleware call"
    @input, env["rack.input"] = env["rack.input"], self

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
    @env["rack.logger"].info "UploadMiddleware#_inc #{@pos}/#{@length}"
    $redis.publish("upload", "#{@pos}/#{@length}")
    if @pos == @length
      @env["rack.logger"].info "UploadMiddleware#_inc done"
      $redis.publish("upload", "done")
    end
  end
end
