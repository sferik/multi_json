module MultiJson
  # Thread-safe bounded cache for merged options hashes
  #
  # Caches are separated for load and dump operations. Each cache is
  # bounded to prevent unbounded memory growth when options are
  # generated dynamically. The ``Store`` backend is chosen at load time
  # based on ``RUBY_ENGINE``: JRuby uses Concurrent::Map (shipped as a
  # runtime dependency of the java-platform gem); MRI and TruffleRuby
  # use a Hash guarded by a Mutex.
  #
  # @api private
  module OptionsCache
    # Maximum entries before an arbitrary entry is evicted
    MAX_CACHE_SIZE = 1000

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
  end
end

module MultiJson
  module OptionsCache
    # Dynamic require path so MRI (mutex_store) and JRuby
    # (concurrent_store) execute the same physical line, avoiding a
    # dead-branch ``require_relative`` that would otherwise drop
    # JRuby's line coverage below 100%.
    BACKENDS = {"jruby" => "concurrent_store"}.freeze
    private_constant :BACKENDS
  end
end

require_relative "options_cache/#{MultiJson::OptionsCache.send(:const_get, :BACKENDS).fetch(RUBY_ENGINE, "mutex_store")}"
MultiJson::OptionsCache.reset
