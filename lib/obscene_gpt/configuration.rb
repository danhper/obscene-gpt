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
    attr_accessor :api_key, :model, :schema, :prompt, :profanity_threshold, :test_mode,
                  :test_detector_class, :request_timeout, :reasoning_effort

    def initialize
      @api_key = ENV.fetch("OPENAI_API_KEY", nil)
      @model = "gpt-6-luna"
      @reasoning_effort = "none"
      @prompt = Prompts::SYSTEM_PROMPT
      @schema = Prompts::SIMPLE_SCHEMA
      @profanity_threshold = 0.8
      @test_mode = false
      @test_detector_class = TestDetector
      @request_timeout = 10
    end
  end
end
