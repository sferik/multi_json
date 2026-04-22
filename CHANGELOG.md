# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0]

`2.0.0` completes the rename-and-tighten work introduced in `1.21.0`. If you've already migrated off the deprecated names under `1.21.0`, this upgrade should be mechanical. If not, run your app or test suite with `ruby -W:deprecated` against `1.21.x` first and migrate the warnings before upgrading.

### Added

- Adapter contract for subclasses of `MultiJSON::Adapter`: implement the private class methods `self._parse(string, options)` and `self._generate(object, options)` to plug into the base class's framework dispatch (IO reading, blank-input guard, option merging). Standalone custom adapters still respond to `.parse` and `.generate` at the class level.
- Replace the two-adapter `Benchmark.ips` smoke test in `benchmark.rb` with a full adapter comparison matrix (`parse` + `generate` across nine workloads) and promote it to a top-level `rake benchmark` task. A new `--verify-preference` flag asserts that `PARSE_ADAPTERS` and `GENERATE_ADAPTERS` each match the observed throughput ranking for their direction, with a 10% tolerance for adjacent ties; CI runs it on every push so the ordering can't silently drift.

### Changed

- `MultiJSON.parse` raises `MultiJSON::ParseError` on `nil`, empty, and whitespace-only input, matching RFC 8259 and Ruby stdlib `JSON.parse`. Previously these inputs returned `nil`.
- `MultiJSON.parse`, `MultiJSON.generate`, and `MultiJSON.current_adapter` use explicit keyword arguments (`symbolize_names:`, `pretty:`, `adapter:`) with an `**opts` splat for adapter-specific options.
- `MultiJSON::Adapter` no longer includes `Singleton`. Built-in adapters are class-method only; the `instance.parse` / `instance.generate` trampoline is gone.
- The options setters (`MultiJSON.parse_options=`, `MultiJSON.generate_options=`, and the per-adapter counterparts) accept only `Hash` or `nil`. `Proc` / lambda values are no longer supported.
- `MultiJSON.use` accepts only Symbols and Modules. Strings are no longer recognized as adapter identifiers; pass a canonical Symbol (`:oj`, `:json_gem`, etc.) or the adapter module itself.
- Module-level `include MultiJSON` and the dual `module_function` / singleton API are gone. Only `MultiJSON.*` class methods remain.
- Split adapter selection into separate `PARSE_ADAPTERS` / `GENERATE_ADAPTERS` preference lists so each direction can pick its fastest backend independently. `default_parse_adapter` and `default_generate_adapter` walk their respective list. `PARSE_ADAPTERS` is reordered so the JSON gem is tried before `fast_jsonparser`/`oj`/`yajl` on MRI and TruffleRuby, matching the bundled benchmark on Ruby 3.4+; the list is split per platform so JRuby still prefers `jr_jackson`. Affects auto-detection only when more than one parse-capable adapter is loaded; explicit selection via `MultiJSON.use(:adapter)` is unchanged.

### Removed

- `MultiJSON.load` / `MultiJSON.dump` — use `MultiJSON.parse` / `MultiJSON.generate`.
- `MultiJSON.load_options` / `MultiJSON.load_options=` / `MultiJSON.dump_options` / `MultiJSON.dump_options=` — use `MultiJSON.parse_options` / `MultiJSON.generate_options`.
- The `MultiJson` (CamelCase) constant alias — use `MultiJSON`.
- The `symbolize_keys:` parse option — use `symbolize_names:`.
- `MultiJSON::DecodeError` and `MultiJSON::LoadError` aliases for `ParseError`.
- `MultiJSON.decode` / `MultiJSON.encode` / `MultiJSON.engine` / `MultiJSON.engine=` / `MultiJSON.default_engine` / `MultiJSON.with_engine`.
- `MultiJSON.default_options` / `MultiJSON.default_options=` / `MultiJSON.cached_options` / `MultiJSON.reset_cached_options!`.

## [1.21.0]

Every deprecation introduced here will be **removed in `2.0.0`**. Upgrade to `1.21.0`, run your app or test suite with `ruby -W:deprecated` to surface the warnings, migrate each call site to the new canonical names, then pin `~> 2.0` once `2.0.0` ships.

### Added

- Rename the `MultiJson` constant to `MultiJSON` (all-caps) to match the project name, Ruby stdlib `JSON`, and the all-caps treatment of the JSON acronym across other languages. The legacy `MultiJson` constant continues to work as a thin delegator via `method_missing` and `const_missing`, so `MultiJson.parse(...)`, `MultiJson::Adapters::Oj`, and `rescue MultiJson::ParseError` all resolve to their `MultiJSON` counterparts.
- Add `MultiJSON.parse` and `MultiJSON.generate` as the new canonical names for the primary parse and generate methods, matching Ruby stdlib `JSON.parse` / `JSON.generate`, the JSON spec (RFC 8259), and sister library [MultiXml](https://github.com/sferik/multi_xml).
- Add `MultiJSON.parse_options` / `MultiJSON.parse_options=` and `MultiJSON.generate_options` / `MultiJSON.generate_options=` as the new canonical option setters.
- Accept `symbolize_names:` as the canonical option name matching Ruby stdlib's `JSON.parse(str, symbolize_names: true)`. The deprecated `symbolize_keys:` option continues to work and emits a one-time warning when passed at any of the three option layers (call-site, `MultiJSON.parse_options=`, adapter `defaults :load`).
- Replace the two-adapter `Benchmark.ips` smoke test in `benchmark.rb` with a full adapter comparison matrix (`parse` + `dump` across nine workloads) and promote it to a top-level `rake benchmark` task. A new `--verify-preference` flag asserts that `MultiJSON::AdapterSelector::ADAPTERS` matches the observed throughput ranking, with a 10% tolerance for adjacent ties; CI runs it on every push so the ordering can't silently drift.

### Changed

- Reorder `MultiJSON::AdapterSelector::ADAPTERS` so the JSON gem is tried before `fast_jsonparser`/`oj`/`yajl` on MRI and TruffleRuby, matching the throughput ranking in the bundled benchmark suite on Ruby 3.4+. The hash is split per platform so JRuby still prefers `jr_jackson`. Affects auto-detection only when more than one of those adapters is loaded; explicitly selecting an adapter with `MultiJSON.use(:adapter)` is unchanged.

### Deprecated

- The `MultiJson` constant in favor of `MultiJSON`.
- `MultiJSON.load` in favor of `MultiJSON.parse`.
- `MultiJSON.dump` in favor of `MultiJSON.generate`.
- `MultiJSON.load_options` / `MultiJSON.load_options=` in favor of `MultiJSON.parse_options` / `MultiJSON.parse_options=`.
- `MultiJSON.dump_options` / `MultiJSON.dump_options=` in favor of `MultiJSON.generate_options` / `MultiJSON.generate_options=`.
- The `:symbolize_keys` parse option in favor of `:symbolize_names`.

All deprecated names continue to work and emit a one-time warning on first use. Warnings are tagged with Ruby's `:deprecated` category, so noisy apps can silence the whole set with `Warning[:deprecated] = false` and deprecation-aware tooling (`ruby -W:deprecated`, CI linters) picks them up. The old names will be removed in 2.0.

## [1.20.1]

### Fixed

- Fix `JsonGem#load` raising `ParseError` on ASCII-8BIT strings that contain valid UTF-8 bytes ([#64](https://github.com/sferik/multi_json/issues/64)). Ruby HTTP clients tag response bodies as ASCII-8BIT by default; the 1.20.0 change from `force_encoding` to `encode` broke the dominant real-world case by trying to transcode each byte individually. Switch back to `force_encoding` followed by a `valid_encoding?` guard so genuinely invalid byte sequences still surface as `ParseError`.

### Added

- Validate custom adapters during `MultiJson.use` and `MultiJson.load`/`dump` with an `:adapter` option, raising `MultiJson::AdapterError` immediately if the adapter does not respond to `.load`, `.dump`, or define a `ParseError` constant.
- Validate `OptionsCache.max_cache_size=` to reject `nil`, zero, negative, and non-integer values with a clear `ArgumentError`.
- Expand the benchmark suite (`benchmark.rb`) into a full adapter comparison matrix covering load, dump, and round-trip across small, medium, and large payloads in both object-heavy and array-heavy shapes.

## [1.20.0]

### Added

- Surface parse error locations as `error.line` and `error.column` on `MultiJson::ParseError`, extracted from the underlying adapter's message for adapters that include one (Oj, the json gem).
- Make `MultiJson::OptionsCache.max_cache_size` configurable so applications that generate many distinct option hashes can raise the cache ceiling at runtime.
- Add YARD documentation for the `Adapters` module and `ParseError` constants.
- Document public API methods as `@api public` so `load`, `dump`, `use`, `with_adapter`, `current_adapter`, `adapter`, `load_options`, and `dump_options` appear in generated docs.
- Type-check the `Yajl`, `JrJackson`, and `Gson` adapter wrappers under Steep, with stubbed RBS sigs for the underlying libraries living in `sig/external_libraries.rbs`.
- Add Ruby 4.0 to the CI matrix.
- Add workflow badges for linter, mutant, steep, and docs.
- Add a `# frozen_string_literal: true` magic comment to every Ruby file in `lib/` and `test/`, enforced by `Style/FrozenStringLiteralComment`.
- Collect the five process-wide mutexes into a new `MultiJson::Concurrency` module, collapsed into a single `Concurrency.synchronize(name, &block)` method with private constants.
- Add a `deprecate_alias` / `deprecate_method` DSL in `lib/multi_json/deprecated.rb` so adding or removing a deprecation is a one-liner.
- Memoize the per-adapter `ParseError` lookup in `MultiJson.parse_error_class_for` so the constant resolution runs at most once per adapter.

### Changed

- Split the gem into `ruby` and `java` platform variants: the `java` variant adds `concurrent-ruby ~> 1.2` as a runtime dependency and ships the `gson` and `jr_jackson` adapters; the `ruby` variant has no runtime dependencies and ships the MRI-only adapters.
- Make `with_adapter` overrides fiber-local so concurrent fibers and threads each observe their own adapter without racing on a shared module variable.
- Raise `MultiJson::ParseError` on invalid UTF-8 in the `json_gem` adapter instead of silently reinterpreting bytes with `force_encoding`.
- Warn once for deprecated method aliases: `decode`, `encode`, `engine`, `engine=`, `default_engine`, and `with_engine` now emit a one-time deprecation warning on first call.
- Emit deprecation warnings only once per process for `default_options`, `default_options=`, `cached_options`, and `reset_cached_options!`.
- Include the original exception's class name in `MultiJson::AdapterError.build`'s formatted message.
- Walk the superclass chain in `Adapter.default_load_options` / `default_dump_options` instead of copying at inheritance time, so a parent calling `defaults :load, ...` after a subclass has been defined now propagates.
- Replace `(...)` argument forwarding in `MultiJson::Options` with explicit `*args` so the signatures are self-documenting.
- Reorganize `lib/multi_json.rb` into clearer sections and document why both the `module_function` and singleton-only definition patterns coexist.
- Restructure `OptionsCache` backend selection so MRI and JRuby execute the same physical `require_relative` line, restoring JRuby's line coverage threshold to 100%.
- Unify `LOADED_ADAPTER_DETECTORS` and `REQUIREMENT_MAP` in `AdapterSelector` into a single `ADAPTERS` source-of-truth.
- Replace the per-adapter `loaded` lambdas in `AdapterSelector::ADAPTERS` with constant name strings walked through `Object.const_defined?` directly.
- Extract deprecated public API into `lib/multi_json/deprecated.rb`.
- Improve `AdapterSelector#load_adapter`'s error message for unrecognized adapter specs.
- Move `Oj#load`'s `:symbolize_keys` translation into a private `translate_load_options` helper.
- Drop the `ALIASES` constant in `AdapterSelector` in favor of an inline `jrjackson` → `jr_jackson` check.
- Drop the `UnannotatedEmptyCollection` Steep diagnostic override.

### Fixed

- Stop mutating cached options in `Oj#load`: the adapter previously assigned `options[:symbol_keys]` on the shared cached hash.
- Stop mutating cached options in `OjCommon#prepare_dump_options`: `merge!(PRETTY_STATE_PROTOTYPE)` on the cached hash removed `:pretty` and added prototype keys on every call.
- Stop mutating cached options in `JsonGem#load`.
- Stop resetting `OptionsCache` when `MultiJson.use` raises so a failed `use(:nonexistent)` no longer discards cached entries.
- Hold `@eviction_mutex` around `ConcurrentStore#reset`'s `@cache.clear` so a JRuby fetcher cannot interleave with a concurrent reset.
- Guard `ConcurrentStore` eviction against a TOCTOU race so two concurrent JRuby threads cannot both exceed `max_cache_size`.
- Restore the mutex around `MutexStore#reset` for TruffleRuby.
- Synchronize `warn_deprecation_once` so concurrent fibers and threads cannot double-emit.
- Make `MultiJson.use`'s `OptionsCache.reset` and `@adapter` swap atomic under a mutex.
- Make `AdapterSelector#default_adapter`'s lazy initializer thread-safe.
- Make `AdapterSelector#default_adapter_excluding` thread-safe.
- Make `Options` `default_load_options` / `default_dump_options` initializers thread-safe.
- Defer the `fast_jsonparser` adapter's dump-delegate resolution until the first `dump` call instead of locking it in at file load time.
- Raise a clear `MultiJson::AdapterError` when a custom adapter does not define a `ParseError` constant.
- Call `to_h` on options to properly handle `JSON::State` objects.
- Fix `TestHelpers.yajl?` to check the actual `yajl-ruby` gem name.
- Fix Bundler 4.0 permission error in CI.
- Stop requiring the `oj` gem from the `fast_jsonparser` adapter ([#63](https://github.com/sferik/multi_json/issues/63)).
- Stop relying on `Oj::ParseError`'s `::SyntaxError` ancestor when matching exceptions.

### Removed

- Remove the vendored `ok_json` adapter and the `ConvertibleHashKeys` helper module.
- Remove the `MultiJson::REQUIREMENT_MAP` legacy alias.
- Drop the dead `JrJackson` dump arity branch.
- Drop the duplicate `Adapter::EMPTY_OPTIONS` constant.
- Drop the redundant `options.except(:adapter)` allocation in `JsonGem#dump`.
- Drop Oj 2.x compatibility branch: the Oj adapter now requires Oj `~> 3.0`.
- Drop support for Ruby 3.0, Ruby 3.1, and JRuby 9.4.

### Performance

- Avoid allocating an options hash on the `dump`/`load` hot path by reusing a shared frozen empty hash.
- Short-circuit empty input in `Adapter.blank?` before falling back to the regex match.
- Short-circuit `Adapter.blank?` on inputs that start with `{` or `[`.
- Skip `String#scrub` in `Adapter.blank?` when the input is already valid UTF-8.
- Skip the per-call hash merge in `JsonGem#dump` when `pretty: true` is the only option.
- Hoist the `block_given?` check in `MutexStore#fetch` outside the critical section.
- Walk the superclass chain manually in `Adapter.walk_default_options` instead of allocating an `ancestors` array.
- Hoist a shared `Gson::Decoder` and `Gson::Encoder` for the empty-options case.
- Forward all merged options through `Yajl#load` instead of honoring only `:symbolize_keys`.
- Validate the `action` and `value` arguments in `Adapter.defaults` at definition time.

## [1.19.1]

### Fixed

- Restore deprecated `encode`/`decode` methods.

## [1.19.0]

### Fixed

- Fix serialization of ActiveSupport-enhanced objects.

## [1.18.0]

### Fixed

- Fix conflict between JSON gem and ActiveSupport ([#222](https://github.com/intridea/multi_json/issues/222)).

## [1.17.0]

### Changed

- Revert minimum Ruby version requirement.

## [1.16.0]

### Added

- Make `json_pure` an alias of `json_gem`.

### Changed

- JsonCommon: force encoding to UTF-8, not binary.
- Stop setting defaults in JsonCommon.
- Move repo from @intridea to @sferik.

### Removed

- Remove NSJSONSerialization.
- Stop referencing `JSON::PRETTY_STATE_PROTOTYPE`.
- Drop support for Ruby versions < 3.2.

## [1.15.0]

### Fixed

- Improve detection of `json_gem` adapter.

## [1.14.1]

### Fixed

- Fix a warning in Ruby 2.7.

## [1.14.0]

### Added

- Support Oj 3.x gem.

## [1.13.1]

### Fixed

- Fix missing stdlib `set` dependency in Oj adapter.

## [1.13.0]

### Fixed

- Make Oj adapter handle `JSON::ParseError` correctly.

## [1.12.2]

### Changed

- Renew gem certificate.

## [1.12.1]

### Fixed

- Prevent memory leak in OptionsCache.

## [1.12.0]

### Performance

- Introduce global options cache to improve performance.

## [1.11.2]

### Fixed

- Only pass one argument to JrJackson when two is not supported.

## [1.11.1]

### Fixed

- Dump method passes options through for JrJackson adapter.

## [1.11.0]

### Changed

- Make all adapters read IO object before load.

## [1.10.1]

### Fixed

- Explicitly require `stringio` for Gson adapter.
- Do not read StringIO object before passing it to JrJackson.

## [1.10.0]

### Performance

- Performance tweaks.

## [1.9.3]

### Fixed

- Convert indent option to Fixnum before passing to Oj.

## [1.9.2]

### Changed

- Enable `use_to_json` option for Oj adapter by default.

## [1.9.1]

### Removed

- Remove unused LoadError file.

## [1.9.0]

### Changed

- Rename `LoadError` to `ParseError`.
- Adapter load failure throws `AdapterError` instead of `ArgumentError`.

## [1.8.4]

### Fixed

- Make Gson adapter explicitly read StringIO object.

## [1.8.3]

### Fixed

- Make JrJackson explicitly read StringIO objects.
- Prevent calling `#downcase` on alias symbols.

## [1.8.2]

### Fixed

- Downcase adapter string name for OS compatibility.

## [1.8.1]

### Fixed

- Let the adapter handle strings with invalid encoding.

## [1.8.0]

### Changed

- Raise `MultiJson::LoadError` on blank input.

## [1.7.9]

### Fixed

- Explicitly require json gem code even when constant is defined.

## [1.7.8]

### Changed

- Reorder JrJackson before `json_gem`.
- Update vendored OkJson to version 43.

## [1.7.7]

### Fixed

- Fix options caching issues.

## [1.7.6]

### Fixed

- Bring back `MultiJson::VERSION` constant.

## [1.7.5]

### Fixed

- Fix warning `*` interpreted as argument prefix.
- Remove stdlib warning.

## [1.7.4]

### Performance

- Cache options for better performance.

## [1.7.3]

### Changed

- Require `json/ext` to ensure extension version gets loaded for `json_gem`.
- Rename JrJackson.
- Prefer JrJackson to JSON gem if present.
- Print a warning if outdated gem versions are used.
- Loosen `required_rubygems_version` for compatibility with Ubuntu 10.04.

## [1.7.2]

### Changed

- Rename Jrjackson adapter to JrJackson.
- Implement `jrjackson` → `jr_jackson` alias for backwards compatibility.
- Update vendored OkJson module.

## [1.7.1]

### Fixed

- Fix capitalization of JrJackson class.

## [1.7.0]

### Added

- Add `load_options`/`dump_options` to MultiJson.
- Add JrJackson adapter.

### Changed

- MultiJson does not modify arguments.
- Enable `quirks_mode` by default for `json_gem`/`json_pure` adapters.
- Raise `ArgumentError` on bad adapter input.

## [1.6.1]

### Fixed

- Revert "Use `JSON.generate` instead of `#to_json`".

## [1.6.0]

### Added

- Add gson.rb support.
- Add `MultiJson.default_options`.
- Add `MultiJson.with_adapter`.

### Changed

- Stringify all possible keys for `ok_json`.
- Use `JSON.generate` instead of `#to_json`.
- Alias `MultiJson::DecodeError` to `MultiJson::LoadError`.

## [1.5.1]

### Fixed

- Do not allow Oj or JSON to create symbols by searching for classes.

## [1.5.0]

### Added

- Add `MultiJson.with_adapter` method.

### Changed

- Stringify all possible keys for `ok_json`.

## [1.4.0]

### Changed

- Allow load/dump of JSON fragments.

## [1.3.7]

### Fixed

- Fix rescue clause for MagLev.
- Remove unnecessary check for string version of options key.
- Explicitly set default adapter when adapter is set to `nil` or `false`.
- Fix Oj `ParseError` mapping for Oj 1.4.0.

## [1.3.6]

### Changed

- Allow adapter-specific options to be passed through to Oj.

## [1.3.5]

### Added

- Add pretty support to Oj adapter.

## [1.3.4]

### Changed

- Use `class << self` instead of `module_function` to create aliases.

## [1.3.3]

### Changed

- Remove deprecation warnings.

## [1.3.2]

### Added

- Add ability to use adapter per call.
- Add and deprecate `default_engine` method.

## [1.3.1]

### Fixed

- Only warn once for each instance a deprecated method is called.

## [1.3.0]

### Changed

- Implement `load`/`dump`; deprecate `decode`/`encode`.
- Rename engines to adapters.

## [1.2.0]

### Added

- Add support for Oj.

## [1.1.0]

### Added

- NSJSONSerialization support for MacRuby.

## [1.0.4]

### Added

- Options can be passed to an engine on encode.

### Fixed

- Set data context to `DecodeError` exception.
- Allow `ok_json` to fall back to `to_json`.
- Add warning when using `ok_json`.

## [1.0.3]

### Added

- Array support for `stringify_keys`.
- Array support for `symbolize_keys`.

## [1.0.2]

### Fixed

- Allow encoding of rootless JSON when `ok_json` is used.

## [1.0.1]

### Fixed

- Correct an issue with `ok_json` not being returned as the default engine.

## [1.0.0]

### Changed

- Only rescue from parsing errors during decoding, not any `StandardError`.
- Rename `okjson` engine and vendored lib to `ok_json`.
- Add StringIO support to json gem and `ok_json`.

### Removed

- Remove ActiveSupport::JSON support.

## [0.0.5]

### Fixed

- Trap all JSON decoding errors; raise `MultiJson::DecodeError`.

## [0.0.4]

### Fixed

- Fix `default_engine` check for json gem.
- Make requirement mapper an Array to preserve order in Ruby versions < 1.9.

[2.0.0]: https://github.com/sferik/multi_json/compare/v1.21.0...v2.0.0
[1.21.0]: https://github.com/sferik/multi_json/compare/v1.20.1...v1.21.0
[1.20.1]: https://github.com/sferik/multi_json/compare/v1.20.0...v1.20.1
[1.20.0]: https://github.com/sferik/multi_json/compare/v1.19.1...v1.20.0
[1.19.1]: https://github.com/sferik/multi_json/compare/v1.19.0...v1.19.1
[1.19.0]: https://github.com/sferik/multi_json/compare/v1.18.0...v1.19.0
[1.18.0]: https://github.com/sferik/multi_json/compare/v1.17.0...v1.18.0
[1.17.0]: https://github.com/sferik/multi_json/compare/v1.16.0...v1.17.0
[1.16.0]: https://github.com/sferik/multi_json/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/sferik/multi_json/compare/v1.14.1...v1.15.0
[1.14.1]: https://github.com/sferik/multi_json/compare/v1.14.0...v1.14.1
[1.14.0]: https://github.com/sferik/multi_json/compare/v1.13.1...v1.14.0
[1.13.1]: https://github.com/sferik/multi_json/compare/v1.13.0...v1.13.1
[1.13.0]: https://github.com/sferik/multi_json/compare/v1.12.2...v1.13.0
[1.12.2]: https://github.com/sferik/multi_json/compare/v1.12.1...v1.12.2
[1.12.1]: https://github.com/sferik/multi_json/compare/v1.12.0...v1.12.1
[1.12.0]: https://github.com/sferik/multi_json/compare/v1.11.2...v1.12.0
[1.11.2]: https://github.com/sferik/multi_json/compare/v1.11.1...v1.11.2
[1.11.1]: https://github.com/sferik/multi_json/compare/v1.11.0...v1.11.1
[1.11.0]: https://github.com/sferik/multi_json/compare/v1.10.1...v1.11.0
[1.10.1]: https://github.com/sferik/multi_json/compare/v1.10.0...v1.10.1
[1.10.0]: https://github.com/sferik/multi_json/compare/v1.9.3...v1.10.0
[1.9.3]: https://github.com/sferik/multi_json/compare/v1.9.2...v1.9.3
[1.9.2]: https://github.com/sferik/multi_json/compare/v1.9.1...v1.9.2
[1.9.1]: https://github.com/sferik/multi_json/compare/v1.9.0...v1.9.1
[1.9.0]: https://github.com/sferik/multi_json/compare/v1.8.4...v1.9.0
[1.8.4]: https://github.com/sferik/multi_json/compare/v1.8.3...v1.8.4
[1.8.3]: https://github.com/sferik/multi_json/compare/v1.8.2...v1.8.3
[1.8.2]: https://github.com/sferik/multi_json/compare/v1.8.1...v1.8.2
[1.8.1]: https://github.com/sferik/multi_json/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/sferik/multi_json/compare/v1.7.9...v1.8.0
[1.7.9]: https://github.com/sferik/multi_json/compare/v1.7.8...v1.7.9
[1.7.8]: https://github.com/sferik/multi_json/compare/v1.7.7...v1.7.8
[1.7.7]: https://github.com/sferik/multi_json/compare/v1.7.6...v1.7.7
[1.7.6]: https://github.com/sferik/multi_json/compare/v1.7.5...v1.7.6
[1.7.5]: https://github.com/sferik/multi_json/compare/v1.7.4...v1.7.5
[1.7.4]: https://github.com/sferik/multi_json/compare/v1.7.3...v1.7.4
[1.7.3]: https://github.com/sferik/multi_json/compare/v1.7.2...v1.7.3
[1.7.2]: https://github.com/sferik/multi_json/compare/v1.7.1...v1.7.2
[1.7.1]: https://github.com/sferik/multi_json/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/sferik/multi_json/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/sferik/multi_json/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/sferik/multi_json/compare/v1.5.1...v1.6.0
[1.5.1]: https://github.com/sferik/multi_json/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/sferik/multi_json/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/sferik/multi_json/compare/v1.3.7...v1.4.0
[1.3.7]: https://github.com/sferik/multi_json/compare/v1.3.6...v1.3.7
[1.3.6]: https://github.com/sferik/multi_json/compare/v1.3.5...v1.3.6
[1.3.5]: https://github.com/sferik/multi_json/compare/v1.3.4...v1.3.5
[1.3.4]: https://github.com/sferik/multi_json/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/sferik/multi_json/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/sferik/multi_json/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/sferik/multi_json/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/sferik/multi_json/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/sferik/multi_json/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/sferik/multi_json/compare/v1.0.4...v1.1.0
[1.0.4]: https://github.com/sferik/multi_json/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/sferik/multi_json/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/sferik/multi_json/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/sferik/multi_json/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/sferik/multi_json/compare/v0.0.5...v1.0.0
[0.0.5]: https://github.com/sferik/multi_json/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/sferik/multi_json/releases/tag/v0.0.4
