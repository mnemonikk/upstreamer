Rainbows! do
  use :ThreadPool # concurrency model to use
  worker_connections 400
  keepalive_timeout 0 # zero disables keepalives entirely
  client_max_body_size 512*1024*1024 # 512 megabytes
  keepalive_requests 666 # default:100
  client_header_buffer_size 2 * 1024 # 2 kilobytes
end

worker_processes 2
stderr_path "log/error.log"
stdout_path "log/output.log"
