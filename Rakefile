require "bundler"
Bundler::GemHelper.install_tasks

require "standard/rake"
require "rubocop/rake_task"
RuboCop::RakeTask.new(:rubocop)

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

desc "Alias for spec"
task test: :spec

desc "Run linters"
task lint: %i[rubocop standard]

desc "Run the default task"
task default: %i[spec lint]
