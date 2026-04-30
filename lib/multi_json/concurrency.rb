# frozen_string_literal: true

module MultiJSON
  # Catalog of process-wide mutexes used to serialize MultiJSON's lazy
  # initializers and adapter swaps. Each mutex protects a distinct
  # piece of mutable state. Callers go through {.synchronize} rather
  # than touching the mutex constants directly so the constants
  # themselves can stay {.private_constant} and the surface of the
  # module is documented in one place.
  #
  # @api private
  module Concurrency
    # Catalog of mutexes keyed by symbolic name. Each entry maps the
    # public name passed to {.synchronize} to the underlying mutex
    # instance. The names are documented inline so callers can find
    # what each mutex protects without leaving this file.
    MUTEXES = {
      # Guards the process-wide `@adapter` swap in `MultiJSON.use` so two
      # threads can't interleave their `OptionsCache.reset` and adapter
      # assignment.
      adapter: Mutex.new,
      # Guards the lazy `@default_adapter` initializer and the
      # `default_adapter_excluding` detection chain in `AdapterSelector`,
      # so the chain runs at most once and `fallback_adapter`'s one-time
      # warning fires at most once.
      default_adapter: Mutex.new,
      # Guards the lazy `default_parse_options` / `default_generate_options`
      # initializers in `MultiJSON::Options`.
      default_options: Mutex.new,
      # Guards the lazy generate-delegate resolution in
      # `MultiJSON::Adapters::FastJsonparser`.
      generate_delegate: Mutex.new
    }.freeze
    private_constant :MUTEXES

    # Run a block while holding the named mutex
    #
    # The ``name`` symbol must be one of the keys in the internal
    # ``MUTEXES`` table; an unknown name raises ``KeyError`` so a
    # typo at the call site fails fast instead of silently dropping
    # synchronization on the floor.
    #
    # @api private
    # @param name [Symbol] mutex identifier
    # @yield block to execute while holding the mutex
    # @return [Object] the block's return value
    # @raise [KeyError] when ``name`` does not match a known mutex
    # @example
    #   MultiJSON::Concurrency.synchronize(:adapter) { ... }
    def self.synchronize(name, &)
      MUTEXES.fetch(name).synchronize(&)
    end
  end
end
