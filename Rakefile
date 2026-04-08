require "bundler/gem_tasks"

# Override release task to skip gem push (handled by GitHub Actions with attestations)
Rake::Task["release"].clear
desc "Build gem and create tag (gem push handled by CI)"
task release: %w[build release:guard_clean release:source_control_push]

require "standard/rake"
require "rubocop/rake_task"
RuboCop::RakeTask.new(:rubocop)

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

begin
  require "steep/rake_task"
  Steep::RakeTask.new
rescue LoadError
  # Steep is not available on JRuby
end

require "yard"
YARD::Rake::YardocTask.new(:yard)

require "yardstick/rake/measurement"
Yardstick::Rake::Measurement.new(:yardstick_measure) do |measurement|
  measurement.output = "doc/coverage.txt"
  measurement.path = Rake::FileList.new("lib/**/*.rb")
end

require "yardstick/rake/verify"
Yardstick::Rake::Verify.new(:yardstick) do |verify|
  verify.threshold = 100
  verify.require_exact_threshold = true
  verify.path = Rake::FileList.new("lib/**/*.rb")
end

desc "Run linters"
task lint: %i[rubocop standard]

desc "Run mutation testing"
task :mutant do
  system({"MUTANT" => "1"}, "bundle", "exec", "mutant", "run") || abort("Mutant failed")
end

desc "Run the default task"
default_tasks = %i[test lint mutant yardstick]
default_tasks << :steep if Rake::Task.task_defined?(:steep)
task default: default_tasks
