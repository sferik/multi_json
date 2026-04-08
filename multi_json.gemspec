require File.expand_path("lib/multi_json/version.rb", __dir__)

Gem::Specification.new do |spec|
  spec.authors = ["Michael Bleigh", "Josh Kalderimis", "Erik Berlin", "Pavel Pravosud"]
  spec.description = if ENV["MULTI_JSON_PLATFORM"] == "java"
    "A common interface to multiple JSON libraries, " \
      "including the JSON gem, gson, and JrJackson."
  else
    "A common interface to multiple JSON libraries, " \
      "including fast_jsonparser, Oj, Yajl, and the JSON gem."
  end
  spec.email = %w[sferik@gmail.com]
  spec.homepage = "https://github.com/sferik/multi_json"
  spec.license = "MIT"
  spec.name = "multi_json"
  spec.require_path = "lib"
  spec.required_ruby_version = ">= 3.2"
  spec.summary = "A common interface to multiple JSON libraries."
  spec.version = MultiJson::Version

  # JRuby-only sources: gson/jr_jackson adapter wrappers and the
  # Concurrent::Map-backed options cache store. Only shipped in the
  # java-platform gem.
  jruby_only_files = %w[
    lib/multi_json/adapters/gson.rb
    lib/multi_json/adapters/jr_jackson.rb
    lib/multi_json/options_cache/concurrent_store.rb
  ]
  # MRI/TruffleRuby-only source: the Mutex-backed options cache store.
  mri_only_files = %w[
    lib/multi_json/options_cache/mutex_store.rb
  ]

  files = Dir["*.md", "lib/**/*"]
  files -= (ENV["MULTI_JSON_PLATFORM"] == "java") ? mri_only_files : jruby_only_files
  spec.files = files

  if RUBY_ENGINE == "jruby"
    spec.platform = "java" if ENV["MULTI_JSON_PLATFORM"] == "java"
    spec.add_dependency "concurrent-ruby", "~> 1.2"
  end

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/sferik/multi_json/issues",
    "changelog_uri" => "https://github.com/sferik/multi_json/blob/v#{spec.version}/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/multi_json/#{spec.version}",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/sferik/multi_json/tree/v#{spec.version}",
    "wiki_uri" => "https://github.com/sferik/multi_json/wiki"
  }
end
