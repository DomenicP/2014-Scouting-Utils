require 'rake/testtask'
require 'rake/clean'

CLEAN.include 'data/teams/*.json'

Rake::TestTask.new do |t|
  t.libs << 'src'
  t.libs << 'test'
end
