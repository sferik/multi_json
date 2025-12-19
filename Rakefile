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

desc "Run linters"
task lint: %i[rubocop standard]

desc "Run mutation testing"
task :mutant do
  system({"MUTANT" => "1"}, "bundle", "exec", "mutant", "run") || abort("Mutant failed")
end

desc "Run the default task"
task default: %i[test lint mutant]
