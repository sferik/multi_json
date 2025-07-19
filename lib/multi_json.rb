require_relative "multi_json/options"
require_relative "multi_json/version"
require_relative "multi_json/adapter_error"
require_relative "multi_json/parse_error"
require_relative "multi_json/options_cache"
require_relative "multi_json/adapter_selector"

module MultiJson
  extend Options
  extend AdapterSelector

  ALIASES = {"jrjackson" => "jr_jackson"}.freeze

  REQUIREMENT_MAP = {
    fast_jsonparser: "fast_jsonparser",
    oj: "oj",
    yajl: "yajl",
    jr_jackson: "jrjackson",
    json_gem: "json",
    gson: "gson"
  }.freeze

  class << self
    public(*AdapterSelector.private_instance_methods(false))

    def default_options=(value)
      Kernel.warn "MultiJson.default_options setter is deprecated\nUse MultiJson.load_options and MultiJson.dump_options instead"
      self.load_options = self.dump_options = value
    end

    def default_options
      Kernel.warn "MultiJson.default_options is deprecated\nUse MultiJson.load_options or MultiJson.dump_options instead"
      load_options
    end

    %w[cached_options reset_cached_options!].each do |method_name|
      define_method method_name do |*|
        Kernel.warn "MultiJson.#{method_name} method is deprecated and no longer used."
      end
    end

    alias_method :default_engine, :default_adapter

    def adapter
      return @adapter if defined?(@adapter) && @adapter

      use nil

      @adapter
    end
    alias_method :engine, :adapter

    def use(new_adapter)
      @adapter = load_adapter(new_adapter)
    ensure
      OptionsCache.reset
    end
    alias_method :adapter=, :use
    alias_method :engine=, :use

    def load(string, options = {})
      adapter = current_adapter(options)
      begin
        adapter.load(string, options)
      rescue adapter::ParseError => e
        raise(ParseError.build(e, string), cause: e)
      end
    end
    alias_method :decode, :load

    def current_adapter(options = {})
      if (new_adapter = options[:adapter])
        load_adapter(new_adapter)
      else
        adapter
      end
    end

    def dump(object, options = {})
      current_adapter(options).dump(object, options)
    end
    alias_method :encode, :dump

    def with_adapter(new_adapter)
      old_adapter = adapter
      self.adapter = new_adapter
      yield
    ensure
      self.adapter = old_adapter
    end
    alias_method :with_engine, :with_adapter
  end
end
