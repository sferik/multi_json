require "singleton"
require_relative "options"

module MultiJson
  # Base class for JSON adapter implementations
  #
  # Each adapter wraps a specific JSON library (Oj, JSON gem, etc.) and
  # provides a consistent interface. Uses Singleton pattern so each adapter
  # class has exactly one instance.
  #
  # Subclasses must implement:
  # - #load(string, options) -> parsed object
  # - #dump(object, options) -> JSON string
  #
  # @api private
  class Adapter
    extend Options
    include Singleton

    class << self
      BLANK_PATTERN = /\A\s*\z/
      EMPTY_OPTIONS = {}.freeze
      VALID_DEFAULTS_ACTIONS = %i[load dump].freeze
      private_constant :BLANK_PATTERN, :EMPTY_OPTIONS, :VALID_DEFAULTS_ACTIONS

      # Hook called when a subclass is created
      #
      # Propagates the parent's current default load/dump options into
      # the subclass at inheritance time. This is a one-shot copy: if
      # the parent later calls {.defaults} again, the change does not
      # flow into already-defined subclasses. Define adapter defaults
      # before subclassing if you need them to flow through.
      #
      # @api private
      # @param subclass [Class] the new subclass
      # @return [void]
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@default_load_options, @default_load_options) if defined?(@default_load_options)
        subclass.instance_variable_set(:@default_dump_options, @default_dump_options) if defined?(@default_dump_options)
      end

      # DSL for setting adapter-specific default options
      #
      # @api private
      # @param action [Symbol] :load or :dump
      # @param value [Hash] default options for the action
      # @return [Hash] the frozen options hash
      # @raise [ArgumentError] when action is anything other than :load or :dump,
      #   or when value isn't a Hash
      def defaults(action, value)
        raise ArgumentError, "expected action to be :load or :dump, got #{action.inspect}" unless VALID_DEFAULTS_ACTIONS.include?(action)
        raise ArgumentError, "expected value to be a Hash, got #{value.class}" unless value.is_a?(Hash)

        instance_variable_set(:"@default_#{action}_options", value.freeze)
      end

      # Parse a JSON string into a Ruby object
      #
      # @api private
      # @param string [String, #read] JSON string or IO-like object
      # @param options [Hash] parsing options
      # @return [Object, nil] parsed object or nil for blank input
      def load(string, options = {})
        string = string.read if string.respond_to?(:read)
        return nil if blank?(string)

        instance.load(string, merged_load_options(options))
      end

      # Serialize a Ruby object to JSON
      #
      # @api private
      # @param object [Object] object to serialize
      # @param options [Hash] serialization options
      # @return [String] JSON string
      def dump(object, options = {})
        instance.dump(object, merged_dump_options(options))
      end

      private

      # Checks if the input is blank (nil, empty, or whitespace-only)
      #
      # ``String#scrub`` is only invoked when the input has invalid
      # encoding so the common valid-UTF-8 path doesn't allocate a
      # scrubbed copy on every call. Scrubbing replaces invalid bytes
      # with U+FFFD before the regex runs so a string with bad bytes
      # is still treated as non-blank without a broad rescue.
      #
      # @api private
      # @param input [String, nil] input to check
      # @return [Boolean] true if input is blank
      def blank?(input)
        input.nil? || input.empty? || BLANK_PATTERN.match?(input.valid_encoding? ? input : input.scrub)
      end

      # Merges dump options from adapter, global, and call-site
      #
      # @api private
      # @param options [Hash] call-site options
      # @return [Hash] merged options hash
      def merged_dump_options(options)
        cache_key = strip_adapter_key(options)
        OptionsCache.dump.fetch(cache_key) do
          dump_options(cache_key).merge(MultiJson.dump_options(cache_key)).merge!(cache_key)
        end
      end

      # Merges load options from adapter, global, and call-site
      #
      # @api private
      # @param options [Hash] call-site options
      # @return [Hash] merged options hash
      def merged_load_options(options)
        cache_key = strip_adapter_key(options)
        OptionsCache.load.fetch(cache_key) do
          load_options(cache_key).merge(MultiJson.load_options(cache_key)).merge!(cache_key)
        end
      end

      # Removes the :adapter key from options for cache key
      #
      # Returns a shared frozen empty hash for the common no-options call
      # path so the hot path avoids allocating a fresh hash on every call.
      #
      # @api private
      # @param options [Hash, #to_h] original options (may be JSON::State or similar)
      # @return [Hash] frozen options without :adapter key
      def strip_adapter_key(options)
        options = options.to_h unless options.is_a?(Hash)
        return EMPTY_OPTIONS if options.empty? || (options.size == 1 && options.key?(:adapter))

        options.except(:adapter).freeze
      end
    end
  end
end
