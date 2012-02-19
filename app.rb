require "sinatra"
require "haml"
require "json"

require "./lib/upload"
require "./lib/upload_middleware"

get "/" do
  haml :index, {}, {:upload_id => Upload.generate_id}
end

post "/upload" do
  upload = Upload.new(params[:upload_id], params[:file])
  upload.save!

  haml :upload, {}, {:upload => upload}
end

get "/progress" do
  stream do |out|
    marker = "<!-- CONTENT -->"
    header, footer = haml(marker).split(marker)
    upload_id = params[:upload_id]

    out << header

    pipe = UploadMiddleware.pipe_reader_for(upload_id)
    while !pipe.eof?
      pos, length = JSON.parse(pipe.gets)
      out << "<script type=\"text/javascript\">parent.upload.progress(#{pos}, #{length});</script>\n"
    end
    pipe.close

    out << footer
  end
end

post "/submit" do
  haml :submit, {}, params
end
