# frozen_string_literal: true

module MultiJson
  # Catalog of process-wide mutexes used to serialize MultiJson's lazy
  # initializers and adapter swaps. Each mutex protects a distinct
  # piece of mutable state. Callers go through the matching
  # ``synchronize_*`` wrapper rather than touching the mutex constant
  # directly so the constants themselves can stay {.private_constant}
  # and the surface of the module is documented in one place.
  #
  # @api private
  module Concurrency
    # Guards the {DEPRECATION_WARNINGS_SHOWN} set in `MultiJson` so the
    # check-then-add pair in `warn_deprecation_once` doesn't race.
    DEPRECATION_WARNINGS = Mutex.new

    # Guards the process-wide `@adapter` swap in `MultiJson.use` so two
    # threads can't interleave their `OptionsCache.reset` and adapter
    # assignment.
    ADAPTER = Mutex.new

    # Guards the lazy `@default_adapter` initializer and the
    # `default_adapter_excluding` detection chain in `AdapterSelector`,
    # so the chain runs at most once and `fallback_adapter`'s one-time
    # warning fires at most once.
    DEFAULT_ADAPTER = Mutex.new

    # Guards the lazy `default_load_options` / `default_dump_options`
    # initializers in `MultiJson::Options`.
    DEFAULT_OPTIONS = Mutex.new

    # Guards the lazy dump-delegate resolution in
    # `MultiJson::Adapters::FastJsonparser`.
    DUMP_DELEGATE = Mutex.new

    private_constant :DEPRECATION_WARNINGS, :ADAPTER, :DEFAULT_ADAPTER, :DEFAULT_OPTIONS, :DUMP_DELEGATE

    class << self
      # Run a block under the deprecation-warning mutex
      #
      # @api private
      # @yield block to execute while holding the mutex
      # @return [Object] the block's return value
      # @example
      #   MultiJson::Concurrency.synchronize_deprecation_warnings { ... }
      def synchronize_deprecation_warnings(&)
        DEPRECATION_WARNINGS.synchronize(&)
      end

      # Run a block under the adapter-swap mutex
      #
      # @api private
      # @yield block to execute while holding the mutex
      # @return [Object] the block's return value
      # @example
      #   MultiJson::Concurrency.synchronize_adapter { ... }
      def synchronize_adapter(&)
        ADAPTER.synchronize(&)
      end

      # Run a block under the default-adapter detection mutex
      #
      # @api private
      # @yield block to execute while holding the mutex
      # @return [Object] the block's return value
      # @example
      #   MultiJson::Concurrency.synchronize_default_adapter { ... }
      def synchronize_default_adapter(&)
        DEFAULT_ADAPTER.synchronize(&)
      end

      # Run a block under the default-options initializer mutex
      #
      # @api private
      # @yield block to execute while holding the mutex
      # @return [Object] the block's return value
      # @example
      #   MultiJson::Concurrency.synchronize_default_options { ... }
      def synchronize_default_options(&)
        DEFAULT_OPTIONS.synchronize(&)
      end

      # Run a block under the FastJsonparser dump-delegate mutex
      #
      # @api private
      # @yield block to execute while holding the mutex
      # @return [Object] the block's return value
      # @example
      #   MultiJson::Concurrency.synchronize_dump_delegate { ... }
      def synchronize_dump_delegate(&)
        DUMP_DELEGATE.synchronize(&)
      end
    end
  end
end
