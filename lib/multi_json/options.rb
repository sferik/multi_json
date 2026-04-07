module MultiJson
  # Mixin providing configurable load/dump options
  #
  # Supports static hashes or dynamic callables (procs/lambdas).
  # Extended by both MultiJson (global options) and Adapter classes.
  #
  # @api private
  module Options
    EMPTY_OPTIONS = {}.freeze
    private_constant :EMPTY_OPTIONS

    # Set options for load operations
    #
    # @api public
    # @param options [Hash, Proc] options hash or callable
    # @return [Hash, Proc] the options
    # @example
    #   MultiJson.load_options = {symbolize_keys: true}
    def load_options=(options)
      OptionsCache.reset
      @load_options = options
    end

    # Set options for dump operations
    #
    # @api public
    # @param options [Hash, Proc] options hash or callable
    # @return [Hash, Proc] the options
    # @example
    #   MultiJson.dump_options = {pretty: true}
    def dump_options=(options)
      OptionsCache.reset
      @dump_options = options
    end

    # Get options for load operations
    #
    # @api public
    # @return [Hash] resolved options hash
    # @example
    #   MultiJson.load_options  #=> {}
    def load_options(...)
      resolve_options(@load_options, ...) || default_load_options
    end

    # Get options for dump operations
    #
    # @api public
    # @return [Hash] resolved options hash
    # @example
    #   MultiJson.dump_options  #=> {}
    def dump_options(...)
      resolve_options(@dump_options, ...) || default_dump_options
    end

    # Get default load options
    #
    # @api private
    # @return [Hash] frozen empty hash
    def default_load_options
      @default_load_options ||= EMPTY_OPTIONS
    end

    # Get default dump options
    #
    # @api private
    # @return [Hash] frozen empty hash
    def default_dump_options
      @default_dump_options ||= EMPTY_OPTIONS
    end

    private

    # Resolves options from a hash or callable
    #
    # @api private
    # @param options [Hash, Proc, nil] options configuration
    # @return [Hash, nil] resolved options hash
    def resolve_options(options, ...)
      return invoke_callable(options, ...) if options.respond_to?(:call)

      options.to_hash if options.respond_to?(:to_hash)
    end

    # Invokes a callable options provider
    #
    # @api private
    # @param callable [Proc] options provider
    # @return [Hash] options returned by the callable
    def invoke_callable(callable, ...)
      callable.arity.zero? ? callable.call : callable.call(...)
    end
  end
end
