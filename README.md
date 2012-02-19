# Upstreamer

Upstreamer is a little Sinatra application that implements a user
friendly upload process. Progress reporting is implemented with a
custom Rack middleware for collecting the data. This data is sent over
a pipe to the progress reporter that outputs script tags to a "forever
frame". Upstreamer currently requires the Rainbows HTTP server to run.  

## Running

Upstreamer uses foreman to start the server process. Invoke

`foreman start`

to start the Rainbows HTTP server.

## License

Upstreamer is available under the terms of the MIT license.

Twitter Bootstrap is licensed under the Apache License 2.0.

The test image test/fixtures/bass.jpg is (cc) http:://www.flickr.com/photos/mourner/
