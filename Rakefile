require "rake"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end
