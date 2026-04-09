module MultiJson
  # Catalog of process-wide mutexes used to serialize MultiJson's lazy
  # initializers and adapter swaps. Each mutex protects a distinct piece
  # of mutable state and lives here so the concurrency surface of the
  # library is documented in one place rather than scattered across the
  # source files that read or write that state.
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
  end
end
