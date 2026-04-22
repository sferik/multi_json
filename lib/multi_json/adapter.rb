# frozen_string_literal: true

require_relative "options"

module MultiJSON
  # Base class for JSON adapter implementations
  #
  # Each adapter wraps a specific JSON library (Oj, JSON gem, etc.) and
  # exposes ``parse`` / ``generate`` as class methods. The base class
  # owns the framework dispatch — reading from IO, the blank-input
  # check, option merging — and forwards the real work to the private
  # class methods {._parse} and {._generate} that every concrete
  # adapter overrides.
  #
  # Subclasses must implement:
  # - ``self._parse(string, options)`` -> parsed object
  # - ``self._generate(object, options)`` -> JSON string
  #
  # @api private
  class Adapter
    extend Options

    class << self
      BLANK_PATTERN = /\A\s*\z/
      VALID_DEFAULTS_ACTIONS = %i[parse generate].freeze
      private_constant :BLANK_PATTERN, :VALID_DEFAULTS_ACTIONS

      # Get default parse options, walking the superclass chain
      #
      # Returns the closest ancestor's `@default_parse_options` ivar so a
      # parent class calling {.defaults} after a subclass has been
      # defined still propagates to the subclass. Falls back to the
      # shared frozen empty hash when no ancestor has defaults set.
      #
      # @api private
      # @return [Hash] frozen options hash
      def default_parse_options
        walk_default_options(:@default_parse_options)
      end

      # Get default generate options, walking the superclass chain
      #
      # @api private
      # @return [Hash] frozen options hash
      def default_generate_options
        walk_default_options(:@default_generate_options)
      end

      # DSL for setting adapter-specific default options
      #
      # ``action`` must be ``:parse`` or ``:generate``; ``value`` must
      # be a Hash. Both arguments are validated up front so a typo at
      # the adapter's class definition fails fast instead of producing
      # a silent no-op default that crashes later in the merge path.
      #
      # @api private
      # @param action [Symbol] :parse or :generate
      # @param value [Hash] default options for the action
      # @return [Hash] the frozen options hash
      # @raise [ArgumentError] when action is anything other than :parse
      #   or :generate, or when value isn't a Hash
      # @example Set parse defaults for an adapter
      #   class MyAdapter < MultiJSON::Adapter
      #     defaults :parse, symbolize_names: false
      #   end
      def defaults(action, value)
        unless VALID_DEFAULTS_ACTIONS.include?(action)
          raise ArgumentError, "expected action to be :parse or :generate, got #{action.inspect}"
        end
        raise ArgumentError, "expected value to be a Hash, got #{value.class}" unless value.is_a?(Hash)

        instance_variable_set(:"@default_#{action}_options", value.freeze)
      end

      # Parse a JSON string into a Ruby object
      #
      # Raises {ParseError} on ``nil``, empty, and whitespace-only
      # input, matching RFC 8259 (which defines empty input as invalid
      # JSON) and Ruby stdlib ``JSON.parse``. The check runs in the base
      # adapter so every underlying library raises the same
      # {ParseError} — some adapters (Oj, Yajl) silently accept blank
      # input and would otherwise return ``nil`` or an empty object
      # instead of signaling the error.
      #
      # @api private
      # @param string [String, #read] JSON string or IO-like object
      # @param options [Hash] parsing options
      # @return [Object] parsed object
      # @raise [ParseError] when input is nil, empty, or whitespace-only
      def parse(string, options = {})
        string = string.read if string.respond_to?(:read)
        raise ParseError, "input cannot be nil" if string.nil?
        raise ParseError, "input cannot be blank" if blank?(string)

        _parse(string, merged_parse_options(options))
      end

      # Serialize a Ruby object to JSON
      #
      # @api private
      # @param object [Object] object to serialize
      # @param options [Hash] serialization options
      # @return [String] JSON string
      def generate(object, options = {})
        _generate(object, merged_generate_options(options))
      end

      private

      # Adapter-specific parse hook
      #
      # Concrete adapters override this private class method to invoke
      # their backing library. Keeping it private communicates that
      # callers outside the adapter hierarchy should go through {.parse}
      # so they get the blank-input guard and merged options.
      #
      # @api private
      # @param _string [String] JSON string (already guaranteed non-blank)
      # @param _options [Hash] merged parse options
      # @return [Object] never — subclass override returns the parsed object
      # @raise [NotImplementedError] always — subclass must override
      def _parse(_string, _options)
        raise NotImplementedError, "#{self} must implement ._parse"
      end

      # Adapter-specific generate hook
      #
      # @api private
      # @param _object [Object] object to serialize
      # @param _options [Hash] merged generate options
      # @return [String] never — subclass override returns the JSON string
      # @raise [NotImplementedError] always — subclass must override
      def _generate(_object, _options)
        raise NotImplementedError, "#{self} must implement ._generate"
      end

      # Walk the superclass chain looking for a default options ivar
      #
      # Stops at the first ancestor whose ``ivar`` is set and returns
      # that value. Returns {Options::EMPTY_OPTIONS} when no ancestor
      # has the ivar set, so adapters without defaults always observe a
      # frozen empty hash instead of nil.
      #
      # @api private
      # @param ivar [Symbol] ivar name (`:@default_parse_options` or `:@default_generate_options`)
      # @return [Hash] frozen options hash
      def walk_default_options(ivar)
        # @type var klass: Class?
        klass = self
        while klass
          return klass.instance_variable_get(ivar) if klass.instance_variable_defined?(ivar)

          klass = klass.superclass
        end
        Options::EMPTY_OPTIONS
      end

      # Checks whether the input is blank (empty or whitespace-only)
      #
      # The hot path — a non-blank string starting with ``{`` or ``[``
      # (the JSON object/array sigils) — takes the ``start_with?``
      # short-circuit and skips the regex entirely. Everything else
      # (numbers, booleans, ``null``, whitespace-prefixed input) falls
      # through to the regex. ``String#scrub`` is only invoked when the
      # input has invalid encoding so the common valid-UTF-8 path
      # doesn't allocate a scrubbed copy on every call; scrubbing
      # replaces invalid bytes with U+FFFD before the regex runs so a
      # string with bad bytes is correctly treated as non-blank without
      # a broad rescue.
      #
      # @api private
      # @param input [String] input to check (never nil — caller guards)
      # @return [Boolean] true if input is blank
      def blank?(input)
        return true if input.empty?
        return false if input.start_with?("{", "[")

        BLANK_PATTERN.match?(input.valid_encoding? ? input : input.scrub)
      end

      # Merges generate options from adapter, global, and call-site
      #
      # @api private
      # @param options [Hash] call-site options
      # @return [Hash] merged options hash
      def merged_generate_options(options)
        cache_key = strip_adapter_key(options)
        OptionsCache.generate.fetch(cache_key) do
          generate_options.merge(MultiJSON.generate_options).merge!(cache_key)
        end
      end

      # Merges parse options from adapter, global, and call-site
      #
      # @api private
      # @param options [Hash] call-site options
      # @return [Hash] merged options hash
      def merged_parse_options(options)
        cache_key = strip_adapter_key(options)
        OptionsCache.parse.fetch(cache_key) do
          parse_options.merge(MultiJSON.parse_options).merge!(cache_key)
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
        return Options::EMPTY_OPTIONS if options.empty? || (options.size == 1 && options.key?(:adapter))

        options.except(:adapter).freeze
      end
    end
  end
end
