require "bundler/gem_tasks"

# Override release task to skip gem push (handled by GitHub Actions)
Rake::Task["release"].clear
desc "Create tag and push to GitHub (gem push handled by CI)"
task release: %w[release:guard_clean release:source_control_push]

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
