require "concurrent/map"

module MultiJson
  module OptionsCache
    # Thread-safe cache store backed by Concurrent::Map
    #
    # Used on JRuby (via the java-platform gem's concurrent-ruby runtime
    # dependency). JRuby has true parallelism, so the plain Hash + Mutex
    # backend on MRI/TruffleRuby is replaced here with Concurrent::Map,
    # which provides lock-free reads and atomic compute_if_absent without
    # needing to serialize the entire fetch path.
    #
    # @api private
    class Store
      # Create a new cache store
      #
      # @api private
      # @return [Store] new store instance
      def initialize
        @cache = Concurrent::Map.new
      end

      # Clear all cached entries
      #
      # @api private
      # @return [void]
      def reset
        @cache.clear
      end

      # Fetch a value from cache or compute it
      #
      # When called with a block, returns the cached value or computes a
      # new one. When called without a block, returns the cached value or
      # the supplied default if the key is missing.
      #
      # @api private
      # @param key [Object] cache key
      # @param default [Object] value to return when key is missing and no
      #   block is given
      # @yield block to compute value if not cached
      # @return [Object] cached, computed, or default value
      def fetch(key, default = nil, &block)
        return @cache[key] || default unless block

        evict_one_if_full
        @cache.compute_if_absent(key, &block)
      end

      private

      # Drop a single arbitrary entry when the cache is at capacity
      #
      # Concurrent::Map has no built-in size cap. We approximate LRU by
      # evicting whichever key Map#keys surfaces first; deterministic
      # ordering is not required, only memory bounding. Iteration must
      # happen outside ``compute_if_absent`` because that block holds the
      # internal cache mutex.
      #
      # @api private
      # @return [void]
      def evict_one_if_full
        return if @cache.size < MAX_CACHE_SIZE

        @cache.delete(@cache.keys.first)
      end
    end
  end
end
