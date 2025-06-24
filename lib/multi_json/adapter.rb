require "singleton"
require_relative "options"

module MultiJson
  class Adapter
    extend Options
    include Singleton

    class << self
      def defaults(action, value)
        define_singleton_method("default_#{action}_options") { value }
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
        input.nil? || /\A\s*\z/.match?(input)
      rescue ArgumentError # invalid byte sequence in UTF-8
        false
      end

      def cached_dump_options(options)
        cached_options(:dump, options)
      end

      def cached_load_options(options)
        cached_options(:load, options)
      end

      def cached_options(type, options)
        opts = options_without_adapter(options)
        OptionsCache.fetch(type, opts) do
          send("#{type}_options", opts)
            .merge(MultiJson.send("#{type}_options", opts))
            .merge!(opts)
        end
      end

      def options_without_adapter(options)
        options[:adapter] ? options.except(:adapter) : options
      end
    end
  end
end
