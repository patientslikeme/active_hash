require 'bundler/setup'
require 'bundler/gem_tasks'
require 'wwtd/tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :wwtd

# override rubygems' normal release task to use Gemfury
Rake::Task['release'].clear
task :release do
  Rake::Task['fury:release'].invoke(nil, "patientslikeme")
end
