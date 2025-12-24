module MultiJson
  # Thread-safe LRU-like cache for merged options hashes.
  #
  # Caches are separated for load and dump operations. Each cache is
  # bounded to prevent unbounded memory growth when options are
  # generated dynamically.
  module OptionsCache
    # Maximum entries before oldest entry is evicted (LRU approximation).
    # Typical usage involves only a handful of option sets, but dynamic
    # options could cause unbounded growth without this limit.
    MAX_CACHE_SIZE = 1000

    # Thread-safe cache store using double-checked locking pattern.
    class Store
      def initialize
        @cache = {}
        @mutex = Mutex.new
      end

      def reset
        @mutex.synchronize { @cache.clear }
      end

      def fetch(key, default = nil)
        # Fast path: check cache without lock (safe for reads)
        return @cache.fetch(key) if @cache.key?(key)

        # Slow path: acquire lock and compute value
        @mutex.synchronize do
          @cache.fetch(key) { block_given? ? store(key, yield) : default }
        end
      end

      private

      def store(key, value)
        # Double-check in case another thread computed while we waited
        @cache.fetch(key) do
          # Evict oldest entry if at capacity (Hash maintains insertion order)
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
