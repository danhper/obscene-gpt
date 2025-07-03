require "json"
require "openai"

module ObsceneGpt
  class Detector
    attr_reader :client, :model, :schema, :prompt

    def initialize(api_key: nil, model: nil, schema: nil, prompt: nil, request_timeout: nil)
      api_key ||= ObsceneGpt.configuration.api_key

      @client = OpenAI::Client.new(
        access_token: api_key,
        request_timeout: request_timeout || ObsceneGpt.configuration.request_timeout,
      )
      @model = model || ObsceneGpt.configuration.model
      @schema = schema || ObsceneGpt.configuration.schema
      @prompt = prompt || ObsceneGpt.configuration.prompt
    end

    # Detects whether the given texts contain obscene content
    # @param texts [Array<String>] The texts to analyze
    # @return [Array<Hash>] An array of hashes containing the detection result with keys:
    #   - :obscene [Boolean] Whether the text contains obscene content
    #   - :confidence [Float] Confidence score (0.0 to 1.0)
    #   - :reasoning [String] Explanation for the classification (only for full schema)
    #   - :categories [Array<String>] Categories of inappropriate content found (only for full schema)
    def detect_many(texts)
      if ObsceneGpt.configuration.test_mode
        test_detector = ObsceneGpt.configuration.test_detector_class.new(schema: @schema)
        return test_detector.detect_many(texts)
      end

      run_detect_many(texts)
    end

    # Detects whether the given text contains obscene content
    # See #detect_many for more details
    def detect(text)
      detect_many([text])[0]
    end

    private

    def run_detect_many(texts)
      response = @client.responses.create(parameters: make_query(texts))

      JSON.parse(response.dig("output", 0, "content", 0, "text"))["results"].map { |r| r.transform_keys(&:to_sym) }
    rescue OpenAI::Error, Faraday::Error => e
      body = e.respond_to?(:response) && e.response.is_a?(Hash) ? e.response[:body] : ""
      raise ObsceneGpt::Error, "OpenAI API error: #{e.message}\n#{body}"
    end

    def make_query(texts)
      text_format = { name: "content-moderation", type: "json_schema", schema: make_schema(texts.length), strict: true }
      {
        model: @model,
        text: { format: text_format },
        input: [{
          role: "user",
          content: [{ type: "input_text", text: @prompt },
                    { type: "input_text", text: JSON.dump(texts) }],
        }],
      }
    end

    def make_schema(texts_count)
      array_schema = { type: "array", items: @schema, minItems: texts_count, maxItems: texts_count }
      {
        type: "object",
        properties: {
          results: array_schema,
        },
        required: %w[results],
        additionalProperties: false,
      }
    end
  end
end
