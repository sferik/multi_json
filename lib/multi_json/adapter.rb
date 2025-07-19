require "singleton"
require_relative "options"

module MultiJson
  class Adapter
    extend Options
    include Singleton

    class << self
      BLANK_RE = /\A\s*\z/
      private_constant :BLANK_RE

      def inherited(subclass)
        super
        if instance_variable_defined?(:@default_load_options)
          subclass.instance_variable_set(:@default_load_options, @default_load_options)
        end
        if instance_variable_defined?(:@default_dump_options)
          subclass.instance_variable_set(:@default_dump_options, @default_dump_options)
        end
      end

      def defaults(action, value)
        instance_variable_set("@default_#{action}_options", value.freeze)
      end

      def load(string, options = {})
        string = string.read if string.respond_to?(:read)
        raise self::ParseError if blank?(string)

        instance.load(string, cached_load_options(options))
      end

      def dump(object, options = {})
        instance.dump(object, cached_dump_options(options))
      end

      private

      def blank?(input)
        input.nil? || BLANK_RE.match?(input)
      rescue ArgumentError # invalid byte sequence in UTF-8
        false
      end

      def cached_dump_options(options)
        opts = options_without_adapter(options)
        OptionsCache.dump.fetch(opts) do
          dump_options(opts).merge(MultiJson.dump_options(opts)).merge!(opts)
        end
      end

      def cached_load_options(options)
        opts = options_without_adapter(options)
        OptionsCache.load.fetch(opts) do
          load_options(opts).merge(MultiJson.load_options(opts)).merge!(opts)
        end
      end

      def options_without_adapter(options)
        options[:adapter] ? options.except(:adapter) : options
      end
    end
  end
end
