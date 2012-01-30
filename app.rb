require 'sinatra'
require './upload_middleware'
require 'haml'
require 'redis'

$redis = Redis.new

use Rack::Session::Pool, :expire_after => 2592000
use UploadMiddleware

get '/' do
  session[:foo] = 1
  haml :layout, {}, :view => :index
end

post "/upload" do
end

get '/progress' do
  stream = Object.new
  def stream.each(&block)
    block.call "<!doctype html>\n<html><head><title>progress</title></head><body>"
    $redis.subscribe("upload") do |subscription|
      subscription.message do |type, message|
        if message == "done"
          $redis.unsubscribe("upload")
        else
          pos, length = message.split("/").map(&:to_i)
          block.call "<script type=\"text/javascript\">parent.upload.progress(#{pos}, #{length});</script>\n"
        end
      end
    end
    block.call "</body></html>"
  end
  stream
end
