require "multi_json"
require "rspec"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # You must run 'bundle exec rake' for this to work properly
  loaded_specs = Gem.loaded_specs

  config.add_setting :java, default: RUBY_PLATFORM == "java"
  config.add_setting :gson, default: loaded_specs.key?("gson")
  config.add_setting :json, default: loaded_specs.key?("json")
  config.add_setting :jrjackson, default: loaded_specs.key?("jrjackson")
  config.add_setting :ok_json, default: loaded_specs.key?("ok_json")
  config.add_setting :oj, default: loaded_specs.key?("oj")
  config.add_setting :yajl, default: loaded_specs.key?("yajl")
  config.add_setting :fast_jsonparser, default: loaded_specs.key?("fast_jsonparser")

  config.filter_run_excluding(:jrjackson) unless config.jrjackson?
  config.filter_run_excluding(:json) unless config.json?
  config.filter_run_excluding(:ok_json) unless config.ok_json?
  config.filter_run_excluding(:oj) unless config.oj?
  config.filter_run_excluding(:yajl) unless config.yajl?
  config.filter_run_excluding(:fast_jsonparser) unless config.fast_jsonparser?

  unless config.java?
    config.filter_run_excluding(:java)
    config.filter_run_excluding(:gson) unless config.gson?
  end
end

def silence_warnings
  old_verbose = $VERBOSE
  $VERBOSE = nil
  yield
ensure
  $VERBOSE = old_verbose
end

def undefine_constants(*consts)
  RSpec::Mocks.with_temporary_scope do
    consts.each { |const| hide_const(const.to_s) }
    yield
  end
end

def break_requirements
  requirements = MultiJson::REQUIREMENT_MAP
  replacements = requirements.transform_values { |library| "foo/#{library}" }

  RSpec::Mocks.with_temporary_scope do
    stub_const("MultiJson::REQUIREMENT_MAP", replacements)
    yield
  end
ensure
  RSpec::Mocks.with_temporary_scope do
    stub_const("MultiJson::REQUIREMENT_MAP", requirements)
  end
end

def simulate_no_adapters(&)
  break_requirements do
    undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser, &)
  end
end

def get_exception(exception_class = StandardError)
  yield
rescue exception_class => e
  e
end

def with_default_options
  adapter = MultiJson.adapter
  adapter.load_options = adapter.dump_options = MultiJson.load_options = MultiJson.dump_options = nil
  yield
ensure
  adapter.load_options = adapter.dump_options = MultiJson.load_options = MultiJson.dump_options = nil
end
