require "bundler"
Bundler::GemHelper.install_tasks

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
task default: %i[test lint]
