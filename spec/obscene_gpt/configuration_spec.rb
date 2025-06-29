require "spec_helper"

RSpec.describe ObsceneGpt::Configuration do
  before do
    # Reset configuration before each test to prevent interference
    ObsceneGpt.instance_variable_set(:@configuration, nil)
  end

  describe "#initialize" do
    it "sets default values" do
      expect(ObsceneGpt.configuration.api_key).to eq(ENV.fetch("OPENAI_API_KEY", nil))
      expect(ObsceneGpt.configuration.model).to eq("gpt-4.1-nano")
      expect(ObsceneGpt.configuration.prompt).to eq(ObsceneGpt::Prompts::SYSTEM_PROMPT)
      expect(ObsceneGpt.configuration.schema).to eq(ObsceneGpt::Prompts::SIMPLE_SCHEMA)
      expect(ObsceneGpt.configuration.test_mode).to be false
      expect(ObsceneGpt.configuration.test_detector_class).to eq(ObsceneGpt::TestDetector)
    end
  end

  describe "#configure" do
    it "allows setting configuration" do
      ObsceneGpt.configure do |config|
        config.api_key = "custom-key"
        config.model = "gpt-3.5-turbo"
        config.schema = { type: "object" }
        config.prompt = "Custom prompt"
        config.test_mode = true
        config.test_detector_class = String
      end

      expect(ObsceneGpt.configuration.api_key).to eq("custom-key")
      expect(ObsceneGpt.configuration.model).to eq("gpt-3.5-turbo")
      expect(ObsceneGpt.configuration.schema).to eq({ type: "object" })
      expect(ObsceneGpt.configuration.prompt).to eq("Custom prompt")
      expect(ObsceneGpt.configuration.test_mode).to be true
      expect(ObsceneGpt.configuration.test_detector_class).to eq(String)
    end
  end

  describe "#configuration" do
    it "returns the configuration instance" do
      expect(ObsceneGpt.configuration).to be_a(ObsceneGpt::Configuration)
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting model" do
      ObsceneGpt.configuration.model = "gpt-3.5-turbo"
      expect(ObsceneGpt.configuration.model).to eq("gpt-3.5-turbo")
    end

    it "allows setting and getting schema" do
      custom_schema = { type: "object", properties: { test: { type: "string" } } }
      ObsceneGpt.configuration.schema = custom_schema
      expect(ObsceneGpt.configuration.schema).to eq(custom_schema)
    end

    it "allows setting and getting prompt" do
      custom_prompt = "Custom moderation prompt"
      ObsceneGpt.configuration.prompt = custom_prompt
      expect(ObsceneGpt.configuration.prompt).to eq(custom_prompt)
    end

    it "allows setting and getting test_mode" do
      ObsceneGpt.configuration.test_mode = true
      expect(ObsceneGpt.configuration.test_mode).to be true

      ObsceneGpt.configuration.test_mode = false
      expect(ObsceneGpt.configuration.test_mode).to be false
    end

    it "allows setting and getting test_detector_class" do
      ObsceneGpt.configuration.test_detector_class = String
      expect(ObsceneGpt.configuration.test_detector_class).to eq(String)

      ObsceneGpt.configuration.test_detector_class = ObsceneGpt::TestDetector
      expect(ObsceneGpt.configuration.test_detector_class).to eq(ObsceneGpt::TestDetector)
    end
  end
end
