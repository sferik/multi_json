module MultiJson
  module ConvertibleHashKeys
    SIMPLE_OBJECT_CLASSES = [String, Numeric, TrueClass, FalseClass, NilClass].freeze
    private_constant :SIMPLE_OBJECT_CLASSES

    private

    def symbolize_keys(value)
      convert_hash_keys(value) { |key| key.respond_to?(:to_sym) ? key.to_sym : key }
    end

    def stringify_keys(value)
      convert_hash_keys(value) { |key| key.respond_to?(:to_s) ? key.to_s : key }
    end

    def convert_hash_keys(value, &key_modifier)
      case value
      when Hash
        value.each_with_object({}) do |(k, v), result|
          result[key_modifier.call(k)] = convert_hash_keys(v, &key_modifier)
        end
      when Array
        value.map { |v| convert_hash_keys(v, &key_modifier) }
      else
        convert_simple_object(value)
      end
    end

    def convert_simple_object(obj)
      return obj if simple_object?(obj) || obj.respond_to?(:to_json)

      obj.respond_to?(:to_s) ? obj.to_s : obj
    end

    def simple_object?(obj)
      SIMPLE_OBJECT_CLASSES.any? { |klass| obj.is_a?(klass) }
    end
  end
end
