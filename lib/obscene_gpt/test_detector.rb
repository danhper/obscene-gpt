module ObsceneGpt
  class TestDetector
    attr_reader :schema

    def initialize(schema: nil)
      @schema = schema || ObsceneGpt::Prompts::SIMPLE_SCHEMA
    end

    # Detects whether the given texts contain obscene content using test mode
    # @param texts [Array<String>] The texts to analyze
    # @return [Array<Hash>] An array of hashes containing the detection result
    def detect_many(texts) # rubocop:disable Metrics/MethodLength
      texts.map do |text|
        # Simple heuristic for test mode: detect common profanity patterns
        is_obscene = detect_obscene_patterns(text)
        confidence = is_obscene ? 0.85 : 0.95

        result = {
          obscene: is_obscene,
          confidence: confidence,
        }

        # Add additional fields if using full schema
        if @schema == Prompts::FULL_SCHEMA
          result[:reasoning] = is_obscene ? "Contains inappropriate content" : "Clean text"
          result[:categories] = is_obscene ? ["profanity"] : []
        end

        result
      end
    end

    # Detects whether the given text contains obscene content
    # @param text [String] The text to analyze
    # @return [Hash] Detection result
    def detect(text)
      detect_many([text])[0]
    end

    private

    def detect_obscene_patterns(text)
      # Simple pattern matching for test mode
      # This is just for testing - not meant to be comprehensive
      profanity_patterns = [
        /\b(fuck|fucked|fucking|shit|bitch|ass|damn|hell)\b/i,
        /\b(sex|porn|nude|naked)\b/i,
        /\b(kill|murder|death|blood)\b/i,
        /\b(hate|racist|sexist)\b/i,
        /\b(gore)\b/i,
      ]

      profanity_patterns.any? { |pattern| text.match?(pattern) }
    end
  end
end
