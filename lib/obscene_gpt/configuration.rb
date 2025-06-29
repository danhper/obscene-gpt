module ObsceneGpt
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end

  class Configuration
    attr_accessor :api_key, :model, :schema, :prompt, :profanity_threshold

    def initialize
      @api_key = ENV.fetch("OPENAI_API_KEY", nil)
      @model = "gpt-4.1-nano"
      @prompt = Prompts::SYSTEM_PROMPT
      @schema = Prompts::SIMPLE_SCHEMA
      @profanity_threshold = 0.8
    end
  end
end
