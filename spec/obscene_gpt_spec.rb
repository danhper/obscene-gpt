RSpec.describe ObsceneGpt do
  it "has a version number" do
    expect(ObsceneGpt::VERSION).not_to be nil
  end

  it "creates detector instances" do
    detector = ObsceneGpt::Detector.new(api_key: "test-key")
    expect(detector).to be_a(ObsceneGpt::Detector)
  end

  describe "configuration" do
    before do
      # Reset configuration by creating a new instance
      ObsceneGpt.instance_variable_set(:@configuration, nil)
    end

    it "provides configuration methods" do
      expect(ObsceneGpt).to respond_to(:configuration)
      expect(ObsceneGpt).to respond_to(:configure)
    end

    it "has a default configuration" do
      config = ObsceneGpt.configuration
      expect(config).to be_a(ObsceneGpt::Configuration)
      expect(config.api_key).to eq(ENV.fetch("OPENAI_API_KEY", nil))
      expect(config.model).to eq("gpt-4.1-nano")
      expect(config.prompt).to eq(ObsceneGpt::Prompts::SYSTEM_PROMPT)
      expect(config.schema).to eq(ObsceneGpt::Prompts::SIMPLE_SCHEMA)
    end

    it "allows configuration via block" do
      ObsceneGpt.configure do |config|
        config.api_key = "custom-key"
        config.model = "gpt-3.5-turbo"
        config.schema = { type: "object" }
        config.prompt = "Custom prompt"
      end

      config = ObsceneGpt.configuration
      expect(config.api_key).to eq("custom-key")
      expect(config.model).to eq("gpt-3.5-turbo")
      expect(config.schema).to eq({ type: "object" })
      expect(config.prompt).to eq("Custom prompt")
    end

    it "uses global configuration for detector creation" do
      ObsceneGpt.configure do |config|
        config.api_key = "global-key"
        config.model = "gpt-3.5-turbo"
      end

      detector = ObsceneGpt::Detector.new
      expect(detector.model).to eq("gpt-3.5-turbo")
    end

    it "allows overriding global configuration" do
      ObsceneGpt.configure do |config|
        config.api_key = "global-key"
        config.model = "gpt-4.1-nano"
      end

      detector = ObsceneGpt::Detector.new(api_key: "override-key", model: "gpt-3.5-turbo")
      expect(detector.model).to eq("gpt-3.5-turbo")
    end
  end
end
