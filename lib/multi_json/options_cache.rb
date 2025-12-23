module MultiJson
  module OptionsCache
    # Normally MultiJson is used with a few option sets for both dump/load
    # methods. When options are generated dynamically though, every call would
    # cause a cache miss and the cache would grow indefinitely. To prevent this,
    # we reset the cache every time the number of keys outgrows 1000.
    MAX_CACHE_SIZE = 1000

    class Store
      def initialize
        @cache = {}
        @mutex = Mutex.new
      end

      def reset
        @mutex.synchronize { @cache.clear }
      end

      def fetch(key, default = nil)
        @cache.fetch(key) do
          @mutex.synchronize do
            @cache.fetch(key) { block_given? ? store_value(key, yield) : default }
          end
        end
      end

      private

      def store_value(key, value)
        @cache.fetch(key) do
          @cache.shift if @cache.size >= MAX_CACHE_SIZE
          @cache[key] = value
        end
      end
    end

    class << self
      attr_reader :dump, :load

      def reset
        @dump = Store.new
        @load = Store.new
      end
    end

    reset
  end
end
