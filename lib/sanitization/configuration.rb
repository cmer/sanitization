module Sanitization
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configuration=(c)
      @configuration = c
    end
  end

  def self.configure
    yield(configuration)
  end

  def self.simple_defaults!
    self.configuration.simple!
  end

  class Configuration
    DEFAULTS = {
      strip: false,
      collapse: false,
      case: :none,
      nullify: false,
      include_text_type: false
    }

    SIMPLE_DEFAULTS = {
      strip: true,
      collapse: true,
      case: :none,
      nullify: true,
      include_text_type: false
    }

    attr_accessor *DEFAULTS.keys

    def initialize(opts = {})
      opts = DEFAULTS.merge((opts || {}).slice(DEFAULTS.keys))

      opts.each_pair do |k,v|
        self.instance_variable_set("@#{k}", v)
      end
    end

    def [](k)
      raise ArgumentError.new("Invalid parameter: #{k}") unless DEFAULTS.keys.include?(k)
      self.instance_variable_get("@#{k}")
    end

    def clear!
      DEFAULTS.each_pair do |k,v|
        self.instance_variable_set("@#{k}", v)
      end; self
    end

    def simple!
      SIMPLE_DEFAULTS.each_pair do |k,v|
        self.instance_variable_set("@#{k}", v)
      end; self
    end
  end
end