require 'sinatra'
require './upload_middleware'
require 'haml'
require 'json'

$pipe = {}
$pipe_mutex = Mutex.new

use UploadMiddleware

def generate_upload_id
  "%0#{128/4}x" % Kernel.rand(2**128 - 1)
end

get "/" do
  haml :index, {}, {:upload_id => generate_upload_id}
end

post "/upload" do
  original_filename = params['fileInput'][:filename]
  filename =
    request.query_string.gsub(/[^0-9a-f]/, "") +
    ".#{File.extname(original_filename)}"
  url = File.join("/upload", filename)

  File.open(File.join("public", url), "w") do |f|
    f.write(params['fileInput'][:tempfile].read)
  end

  haml :upload, {},
    {:filename => original_filename,
     :url      => url}
end

get '/progress' do
  content_marker = "<!-- CONTENT -->"
  header, footer = haml(:layout, {:layout => false}).split(content_marker)

  stream = OpenStruct.new(
    :header    => header,
    :footer    => footer,
    :upload_id => request.query_string)
  def stream.each
    yield header

    pipe = nil
    $pipe_mutex.synchronize do
      pipe, _ = $pipe[upload_id]
      unless pipe
        pipe, _ = $pipe[upload_id] = IO.pipe
      end
    end

    while !pipe.eof?
      pos, length = JSON.parse(pipe.gets)
      yield "<script type=\"text/javascript\">parent.upload.progress(#{pos}, #{length});</script>\n"
    end
    pipe.close

    yield footer
  end
  stream
end
