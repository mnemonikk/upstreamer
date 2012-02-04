class Upload
  attr_reader :url, :original_filename

  def self.generate_id
    "%0#{128/4}x" % Kernel.rand(2**128 - 1)
  end

  def initialize(upload_id, param)
    @id                = upload_id
    @original_filename = param[:filename]
    @tempfile          = param[:tempfile]
    @filename          =
      @id.gsub(/[^0-9a-f]/, "") +
      File.extname(@original_filename)
    @url  = File.join("/upload", @filename)
    @path = File.join("public", @url)
  end

  def save!
    File.open(@path, "w") do |f|
      f.write(@tempfile.read)
    end
  end
end
