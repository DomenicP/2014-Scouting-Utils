require "rake/testtask"
require 'benchmark'

Rake::TestTask.new do |t|
  t.libs << 'src'
  t.libs << 'test'
end

desc "Benchmark the app"
task :benchmark do
  puts Benchmark.measure { ruby "src/mar_scouting.rb" }
end

desc "Run Tests"
task :default => :test
