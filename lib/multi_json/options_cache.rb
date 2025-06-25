module MultiJson
  module OptionsCache
    extend self

    # Normally MultiJson is used with a few option sets for both dump/load
    # methods. When options are generated dynamically though, every call would
    # cause a cache miss and the cache would grow indefinitely. To prevent
    # this, we just reset the cache every time the number of keys outgrows
    # 1000.
    MAX_CACHE_SIZE = 1000
    MUTEX = Mutex.new
    private_constant :MAX_CACHE_SIZE, :MUTEX

    def reset
      MUTEX.synchronize do
        @dump_cache = {}
        @load_cache = {}
      end
    end

    def fetch(type, key, &)
      cache = nil
      MUTEX.synchronize do
        cache = cache_for(type)
        return cache[key] if cache.key?(key)
      end

      value = yield
      MUTEX.synchronize { value = write_cache(cache_for(type), key, value) }
      value
    end

    private

    def cache_for(type)
      if type == :dump
        @dump_cache ||= {}
      else
        @load_cache ||= {}
      end
    end

    def write_cache(cache, key, value)
      if cache.key?(key)
        cache[key]
      else
        cache.clear if cache.length >= MAX_CACHE_SIZE
        cache[key] = value
      end
    end
  end
end
