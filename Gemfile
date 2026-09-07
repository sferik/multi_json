# frozen_string_literal: true

source "https://rubygems.org"

# activesupport 8.x requires Ruby >= 3.2 and 7.2.x requires Ruby >= 3.1.
activesupport_version = if RUBY_VERSION >= "3.2"
  "~> 8.0"
elsif RUBY_VERSION >= "3.1"
  "~> 7.2.0"
else
  "~> 7.1.0"
end
gem "activesupport", activesupport_version, require: false
gem "concurrent-ruby", "~> 1.2", require: false
gem "json", "~> 2.0", require: false

gem "minitest", ">= 5.20"
# mutant 0.12+ requires Ruby >= 3.0, and the 0.11.x releases that run on
# 2.7 pin a parser version rubocop no longer accepts. The mutant job only
# runs on the latest Ruby, so the gem is simply left out on 2.7.
gem "mutant-minitest", ">= 0.12" if RUBY_VERSION >= "3.0"
gem "rake", ">= 13.1"
if RUBY_ENGINE == "jruby"
  # rdoc 8 depends on rbs, whose native extension does not build on JRuby
  gem "rdoc", ">= 7.0.3", "< 8"
else
  gem "rdoc", ">= 7.0.3"
end
# On Ruby 2.7 these resolve to standard 1.37 and rubocop 1.64, the newest
# releases that still install there; .rubocop.yml adapts to that rubocop.
gem "rubocop", ">= 1.62.1"
gem "rubocop-minitest", ">= 0.35"
gem "rubocop-performance", ">= 1.20.2"
gem "rubocop-rake", ">= 0.6.0"
# rubocop-ast 1.41+ prints a deprecation (with a backtrace) for every
# `ensure` block rubocop 1.64's Style/RedundantAssignment inspects; cap it
# on the Ruby that is stuck on rubocop 1.64.
gem "rubocop-ast", "< 1.41" if RUBY_VERSION < "3.0"
# simplecov 1.x requires Ruby >= 3.2.
gem "simplecov", (RUBY_VERSION >= "3.2") ? ">= 1" : "~> 0.22"
gem "standard", ">= 1.35.1"
# steep 1.10+ and rbs 4.x require Ruby >= 3.2; the typecheck job only runs on the latest Ruby.
gem "steep", ">= 1.10", platforms: %i[ruby windows] if RUBY_VERSION >= "3.2"
gem "yard", ">= 0.9.38"
gem "yardstick", ">= 0.9.9"

# fast_jsonparser's simdjson extension is not verified to build on Ruby
# 2.7; the default_adapter_excluding test skips when it is absent.
gem "fast_jsonparser", "~> 0.6", platforms: %i[ruby windows], require: false if RUBY_VERSION >= "3.0"
gem "gson", ">= 0.6", platforms: [:jruby], require: false
gem "jrjackson", ">= 0.4.18", platforms: [:jruby], require: false
gem "oj", "~> 3.0", platforms: %i[ruby windows], require: false
gem "yajl-ruby", "~> 1.3", platforms: %i[ruby windows], require: false

gemspec
