# frozen_string_literal: true

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
        @eviction_mutex = Mutex.new
      end

      # Clear all cached entries
      #
      # Held under {@eviction_mutex} so a concurrent JRuby thread inside
      # the {fetch} miss path cannot interleave its evict-then-insert
      # sequence with a clear and leave the cache in a partially
      # populated state. Mirrors {MutexStore#reset}'s mutex usage.
      #
      # @api private
      # @return [void]
      def reset
        @eviction_mutex.synchronize { @cache.clear }
      end

      # Fetch a value from cache or compute it
      #
      # When called with a block, returns the cached value or computes a
      # new one. When called without a block, returns the cached value or
      # the supplied default if the key is missing.
      #
      # The fast path (cache hit) is lock-free. The miss path takes a small
      # mutex around the evict-then-insert sequence so concurrent inserts
      # cannot both pass the size check and exceed ``max_cache_size``.
      #
      # @api private
      # @param key [Object] cache key
      # @param default [Object] value to return when key is missing and no
      #   block is given
      # @yield block to compute value if not cached
      # @return [Object] cached, computed, or default value
      def fetch(key, default = nil, &block)
        return @cache[key] || default unless block

        cached = @cache[key]
        return cached if cached

        @eviction_mutex.synchronize do
          evict_one_if_full
          @cache.compute_if_absent(key, &block)
        end
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
        return if @cache.size < OptionsCache.max_cache_size

        @cache.delete(@cache.keys.first)
      end
    end
  end
end
