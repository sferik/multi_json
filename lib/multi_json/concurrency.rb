# frozen_string_literal: true

module MultiJSON
  # Catalog of process-wide mutexes used to serialize MultiJSON's lazy
  # initializers and adapter swaps. Each mutex protects a distinct
  # piece of mutable state.
  #
  # @api private
  module Concurrency
    # Catalog of mutexes keyed by symbolic name. Each entry maps the
    # public name passed to {.synchronize} to the underlying mutex
    # instance.
    MUTEXES = {
      # Guards the process-wide parse/generate adapter swaps in
      # `MultiJSON.use`, `MultiJSON.parse_adapter=`, and
      # `MultiJSON.generate_adapter=`.
      adapter: Mutex.new,
      # Guards the lazy parse/generate default-adapter initializers and
      # the `default_adapter_excluding` detection chain in
      # `AdapterSelector`.
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
