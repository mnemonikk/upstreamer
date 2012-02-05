# -*- mode: ruby -*-

require './app'

use UploadMiddleware
run Sinatra::Application
