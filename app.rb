require "sinatra"
require "haml"
require "json"

require "./lib/upload"
require "./lib/upload_middleware"

get "/" do
  haml :index, {}, {:upload_id => Upload.generate_id}
end

post "/upload" do
  upload = Upload.new(request.query_string, params["file"])
  upload.save!

  haml :upload, {}, {:upload => upload}
end

get "/progress" do
  stream do |out|
    header, footer = haml(:empty).split("<!-- CONTENT -->")
    upload_id = request.query_string

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
