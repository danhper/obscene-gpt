require_relative "obscene_gpt/version"
require_relative "obscene_gpt/prompts"
require_relative "obscene_gpt/configuration"
require_relative "obscene_gpt/detector"
require_relative "obscene_gpt/active_model"

module ObsceneGpt
  class Error < StandardError; end

  class << self
    def detect_many(texts)
      ObsceneGpt::Detector.new.detect_many(texts)
    end

    def detect(text)
      ObsceneGpt::Detector.new.detect(text)
    end
  end
end
