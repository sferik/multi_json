require "bundler"
Bundler::GemHelper.install_tasks

require "standard/rake"
require "rubocop/rake_task"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:base_spec) do |task|
  task.pattern = "spec/{multi_json,options_cache}_spec.rb"
end

namespace :adapters do
  Dir["spec/multi_json/adapters/*_spec.rb"].each do |adapter_spec|
    adapter_name = adapter_spec[/(\w+)_spec/, 1]
    desc "Run #{adapter_name} adapter specs"
    RSpec::Core::RakeTask.new(adapter_name) do |task|
      task.pattern = adapter_spec
    end
  end
end

desc "Run the full test suite"
task spec: %w[
  base_spec
  adapters:fast_jsonparser
  adapters:oj
  adapters:yajl
  adapters:json_gem
  adapters:json_pure
  adapters:ok_json
  adapters:gson
  adapters:jr_jackson
]

desc "Run the default task"
task default: :spec

desc "Alias for spec"
task test: :spec
