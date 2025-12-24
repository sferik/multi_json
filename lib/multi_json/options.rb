module MultiJson
  # Mixin providing configurable load/dump options with support for
  # static hashes or dynamic callables (procs/lambdas).
  #
  # Extended by both MultiJson (global options) and Adapter classes.
  module Options
    EMPTY_OPTIONS = {}.freeze
    private_constant :EMPTY_OPTIONS

    def load_options=(options)
      OptionsCache.reset
      @load_options = options
    end

    def dump_options=(options)
      OptionsCache.reset
      @dump_options = options
    end

    def load_options(...)
      resolve_options(@load_options, ...) || default_load_options
    end

    def dump_options(...)
      resolve_options(@dump_options, ...) || default_dump_options
    end

    def default_load_options
      @default_load_options ||= EMPTY_OPTIONS
    end

    def default_dump_options
      @default_dump_options ||= EMPTY_OPTIONS
    end

    private

    def resolve_options(options, ...)
      return invoke_callable(options, ...) if options.respond_to?(:call)

      options.to_hash if options.respond_to?(:to_hash)
    end

    def invoke_callable(callable, ...)
      callable.arity.zero? ? callable.call : callable.call(...)
    end
  end
end
