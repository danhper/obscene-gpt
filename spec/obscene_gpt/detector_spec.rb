require "spec_helper"

RSpec.describe ObsceneGpt::Detector do
  before do
    # Reset configuration before each test to prevent interference
    ObsceneGpt.instance_variable_set(:@configuration, nil)
  end

  let(:api_key) { "test-api-key" }
  let(:detector) { described_class.new(api_key: api_key) }

  describe "#initialize" do
    it "creates a detector with the given API key" do
      expect(detector.client).to be_a(OpenAI::Client)
      expect(detector.model).to eq("gpt-4.1-nano")
    end

    it "uses environment variable when no API key is provided" do
      allow(ENV).to receive(:fetch).with("OPENAI_API_KEY", nil).and_return("env-api-key")
      detector = described_class.new
      expect(detector.client).to be_a(OpenAI::Client)
    end

    it "allows custom model selection" do
      detector = described_class.new(api_key: api_key, model: "gpt-3.5-turbo")
      expect(detector.model).to eq("gpt-3.5-turbo")
    end

    it "allows custom schema and prompt" do
      custom_schema = { type: "object", properties: { test: { type: "string" } } }
      custom_prompt = "Custom prompt"
      detector = described_class.new(api_key: api_key, schema: custom_schema, prompt: custom_prompt)
      expect(detector.schema).to eq(custom_schema)
      expect(detector.prompt).to eq(custom_prompt)
    end
  end

  describe "#detect" do
    let(:mock_response) do
      {
        "output" => [
          {
            "content" => [
              {
                "text" => '{"results": [{"obscene": false, "confidence": 0.95, "reasoning": "Clean text", "categories": []}]}', # rubocop:disable Layout/LineLength
              },
            ],
          },
        ],
      }
    end

    before do
      allow(detector.client).to receive(:responses).and_return(double(create: mock_response))
    end

    it "detects clean text correctly" do
      result = detector.detect("Hello, how are you today?")

      expect(result).to be_a(Hash)
      expect(result[:obscene]).to be false
      expect(result[:confidence]).to eq(0.95)
      expect(result[:reasoning]).to eq("Clean text")
      expect(result[:categories]).to eq([])
    end

    it "handles OpenAI API errors" do
      allow(detector.client).to receive(:responses).and_raise(OpenAI::Error.new("API error"))

      expect { detector.detect("test") }.to raise_error(ObsceneGpt::Error, /OpenAI API error: API error/)
    end

    it "calls OpenAI API with correct parameters" do
      expect(detector.client).to receive(:responses).and_return(
        double(create: mock_response),
      )

      detector.detect("test text")
    end
  end

  describe "#detect_many" do
    let(:mock_response) do
      {
        "output" => [
          {
            "content" => [
              {
                "text" => '{"results": [{"obscene": false, "confidence": 0.95}, {"obscene": true, "confidence": 0.8}]}',
              },
            ],
          },
        ],
      }
    end

    before do
      allow(detector.client).to receive(:responses).and_return(double(create: mock_response))
    end

    it "detects multiple texts correctly" do
      results = detector.detect_many(["Hello", "Bad word"])

      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      expect(results[0][:obscene]).to be false
      expect(results[1][:obscene]).to be true
    end
  end

  describe "test mode" do
    before do
      ObsceneGpt.configure { |config| config.test_mode = true }
    end

    after do
      ObsceneGpt.configure { |config| config.test_mode = false }
    end

    it "returns mock responses when test mode is enabled" do
      # Should not make any API calls
      expect(detector.client).not_to receive(:responses)

      result = detector.detect("Hello, world!")

      expect(result).to be_a(Hash)
      expect(result[:obscene]).to be false
      expect(result[:confidence]).to eq(0.95)
    end

    it "detects profanity patterns in test mode" do
      result = detector.detect("This is a fuck test")

      expect(result[:obscene]).to be true
      expect(result[:confidence]).to eq(0.85)
    end

    it "handles multiple texts in test mode" do
      results = detector.detect_many(["Hello", "This is shit", "Good morning"])

      expect(results).to be_an(Array)
      expect(results.length).to eq(3)
      expect(results[0][:obscene]).to be false
      expect(results[1][:obscene]).to be true
      expect(results[2][:obscene]).to be false
    end

    it "includes additional fields when using full schema" do
      detector = described_class.new(
        api_key: api_key,
        schema: ObsceneGpt::Prompts::FULL_SCHEMA,
      )

      result = detector.detect("This is a fuck test")

      expect(result[:obscene]).to be true
      expect(result[:confidence]).to eq(0.85)
      expect(result[:reasoning]).to eq("Contains inappropriate content")
      expect(result[:categories]).to eq(["profanity"])
    end

    it "detects various profanity patterns" do
      profane_texts = [
        "This is fucked up",
        "I hate this",
        "Blood and gore",
        "Naked pictures",
        "Racist comments",
      ]

      results = detector.detect_many(profane_texts)

      results.each do |result|
        expect(result[:obscene]).to be true
        expect(result[:confidence]).to eq(0.85)
      end
    end

    it "correctly identifies clean text" do
      clean_texts = [
        "Hello, how are you?",
        "The weather is nice today",
        "Programming is fun",
        "Have a great day!",
      ]

      results = detector.detect_many(clean_texts)

      results.each do |result|
        expect(result[:obscene]).to be false
        expect(result[:confidence]).to eq(0.95)
      end
    end

    it "uses the configured test detector class" do
      custom_test_detector = Class.new do
        def initialize(schema: nil)
          @schema = schema
        end

        def detect_many(texts)
          texts.map { |text| { obscene: text.include?("custom"), confidence: 0.9 } }
        end

        def detect(text)
          detect_many([text])[0]
        end
      end

      ObsceneGpt.configure do |config|
        config.test_mode = true
        config.test_detector_class = custom_test_detector
      end

      result = detector.detect("This is a custom test")
      expect(result[:obscene]).to be true
      expect(result[:confidence]).to eq(0.9)

      result = detector.detect("This is a normal test")
      expect(result[:obscene]).to be false
      expect(result[:confidence]).to eq(0.9)
    end

    it "passes schema to the test detector" do
      custom_test_detector = Class.new do
        attr_reader :schema

        def initialize(schema: nil)
          @schema = schema
        end

        def detect_many(texts)
          texts.map { |text| { obscene: false, confidence: 0.9, schema: @schema } }
        end

        def detect(text)
          detect_many([text])[0]
        end
      end

      ObsceneGpt.configure do |config|
        config.test_mode = true
        config.test_detector_class = custom_test_detector
      end

      full_schema_detector = described_class.new(
        api_key: api_key,
        schema: ObsceneGpt::Prompts::FULL_SCHEMA,
      )

      result = full_schema_detector.detect("test")
      expect(result[:schema]).to eq(ObsceneGpt::Prompts::FULL_SCHEMA)
    end
  end

  describe "response parsing" do
    it "handles valid JSON responses" do
      mock_response = {
        "output" => [
          {
            "content" => [
              {
                "text" => '{"results": [{"obscene": true, "confidence": 0.8, "reasoning": "Test", "categories": ["profanity"]}]}', # rubocop:disable Layout/LineLength
              },
            ],
          },
        ],
      }

      allow(detector.client).to receive(:responses).and_return(double(create: mock_response))

      result = detector.detect("test")
      expect(result[:obscene]).to be true
      expect(result[:confidence]).to eq(0.8)
      expect(result[:reasoning]).to eq("Test")
      expect(result[:categories]).to eq(["profanity"])
    end

    it "handles API errors with response body" do
      error = OpenAI::Error.new("API error")
      allow(error).to receive(:response).and_return({ body: "Error details" })
      allow(detector.client).to receive(:responses).and_raise(error)

      expect { detector.detect("test") }.to raise_error(ObsceneGpt::Error, /OpenAI API error: API error\nError details/)
    end
  end
end
