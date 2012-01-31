require 'sinatra'
require 'haml'
require 'json'


$pipe = {}
$pipe_mutex = Mutex.new
def pipes_for(upload_id)
  $pipe_mutex.synchronize do
    $pipe[upload_id] ||= IO.pipe
  end
end

def generate_upload_id
  "%0#{128/4}x" % Kernel.rand(2**128 - 1)
end


require './upload_middleware'
use UploadMiddleware


get "/" do
  haml :index, {}, {:upload_id => generate_upload_id}
end

post "/upload" do
  original_filename = params['fileInput'][:filename]
  filename =
    request.query_string.gsub(/[^0-9a-f]/, "") +
    File.extname(original_filename)
  url = File.join("/upload", filename)

  File.open(File.join("public", url), "w") do |f|
    f.write(params['fileInput'][:tempfile].read)
  end

  haml :upload, {},
    {:filename => original_filename,
     :url      => url}
end

get '/progress' do
  stream do |out|
    content_marker = "<!-- CONTENT -->"
    header, footer = haml(:layout, {:layout => false}).split(content_marker)
    upload_id = request.query_string

    out << header

    pipe, _ = pipes_for(upload_id)

    while !pipe.eof?
      pos, length = JSON.parse(pipe.gets)
      out << "<script type=\"text/javascript\">parent.upload.progress(#{pos}, #{length});</script>\n"
    end
    pipe.close

    out << footer
  end
end
