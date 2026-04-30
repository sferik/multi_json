# frozen_string_literal: true

module MultiJSON
  # Mixin providing configurable parse/generate options
  #
  # Options are plain hashes: the callable (Proc/lambda) form that
  # {MultiJSON.load_options=} / {MultiJSON.dump_options=} accepted in
  # 1.x was removed in 2.0 because it carried significant type-surface
  # complexity and had no known downstream consumers.
  #
  # Extended by both MultiJSON (global options) and Adapter classes.
  #
  # @api private
  module Options
    # Steep needs an inline `#:` annotation here because `{}.freeze`
    # would be inferred as `Hash[untyped, untyped]` and trip
    # `UnannotatedEmptyCollection`. The annotation requires
    # `Hash.new.freeze` (not the `{}.freeze` rubocop would prefer)
    # because the `#:` cast only applies to method-call results.
    EMPTY_OPTIONS = Hash.new.freeze #: options # rubocop:disable Style/EmptyLiteral

    # Set options for parse operations
    #
    # @api public
    # @param options [Hash, nil] options hash or nil to clear
    # @return [Hash, nil] the options
    # @raise [ArgumentError] when ``options`` is neither a Hash nor nil
    # @example
    #   MultiJSON.parse_options = {symbolize_names: true}
    def parse_options=(options)
      raise ArgumentError, "expected a Hash or nil, got #{options.class}" unless options.nil? || options.is_a?(Hash)

      OptionsCache.reset
      @parse_options = options
    end

    # Set options for generate operations
    #
    # @api public
    # @param options [Hash, nil] options hash or nil to clear
    # @return [Hash, nil] the options
    # @raise [ArgumentError] when ``options`` is neither a Hash nor nil
    # @example
    #   MultiJSON.generate_options = {pretty: true}
    def generate_options=(options)
      raise ArgumentError, "expected a Hash or nil, got #{options.class}" unless options.nil? || options.is_a?(Hash)

      OptionsCache.reset
      @generate_options = options
    end

    # Get options for parse operations
    #
    # @api public
    # @return [Hash] resolved options hash
    # @example
    #   MultiJSON.parse_options  #=> {}
    def parse_options
      @parse_options || default_parse_options
    end

    # Get options for generate operations
    #
    # @api public
    # @return [Hash] resolved options hash
    # @example
    #   MultiJSON.generate_options  #=> {}
    def generate_options
      @generate_options || default_generate_options
    end

    # Get default parse options
    #
    # @api private
    # @return [Hash] frozen empty hash
    def default_parse_options
      Concurrency.synchronize(:default_options) { @default_parse_options ||= EMPTY_OPTIONS }
    end

    # Get default generate options
    #
    # @api private
    # @return [Hash] frozen empty hash
    def default_generate_options
      Concurrency.synchronize(:default_options) { @default_generate_options ||= EMPTY_OPTIONS }
    end
  end
end
