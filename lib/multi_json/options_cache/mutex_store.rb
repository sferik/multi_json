module MultiJson
  module OptionsCache
    # Thread-safe cache store backed by a Hash guarded by a Mutex
    #
    # Used on MRI and TruffleRuby, where a runtime dependency on
    # concurrent-ruby would be overkill: the GVL on MRI makes single
    # lookups atomic, and locking on both reads and writes keeps the
    # small perf cost predictable across engines without adding a
    # runtime dependency.
    #
    # @api private
    class Store
      # Create a new cache store
      #
      # @api private
      # @return [Store] new store instance
      def initialize
        @cache = {}
        @mutex = Mutex.new
      end

      # Clear all cached entries
      #
      # ``Hash#clear`` is atomic under the MRI GVL, and a concurrent
      # fetch holds its own mutex acquire (so it either ran to completion
      # before reset or will see a cleared cache on its next acquire).
      # No explicit synchronization is needed here.
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
      # the supplied default if the key is missing. Nil cached values are
      # preserved because ``Hash#fetch`` only falls through to the default
      # block when the key is truly missing.
      #
      # @api private
      # @param key [Object] cache key
      # @param default [Object] value to return when key is missing and no
      #   block is given
      # @yield block to compute value if not cached
      # @return [Object] cached, computed, or default value
      def fetch(key, default = nil)
        @mutex.synchronize do
          return @cache.fetch(key) { default } unless block_given?

          @cache.fetch(key) do
            @cache.shift if @cache.size >= MAX_CACHE_SIZE
            @cache[key] = yield
          end
        end
      end
    end
  end
end
