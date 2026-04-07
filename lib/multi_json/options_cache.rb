require "concurrent/map"

module MultiJson
  # Thread-safe bounded cache for merged options hashes
  #
  # Caches are separated for load and dump operations. Each cache is
  # bounded to prevent unbounded memory growth when options are
  # generated dynamically. Uses Concurrent::Map for lock-free reads on
  # both MRI and JRuby.
  #
  # @api private
  module OptionsCache
    # Maximum entries before an arbitrary entry is evicted
    MAX_CACHE_SIZE = 1000

    # Thread-safe cache store backed by Concurrent::Map
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

    class << self
      # Get the dump options cache
      #
      # @api private
      # @return [Store] dump cache store
      attr_reader :dump

      # Get the load options cache
      #
      # @api private
      # @return [Store] load cache store
      attr_reader :load

      # Reset both caches
      #
      # @api private
      # @return [void]
      def reset
        @dump = Store.new
        @load = Store.new
      end
    end

    reset
  end
end
