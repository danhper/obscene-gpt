require "spec_helper"

RSpec.describe ObsceneGpt::TestDetector do
  let(:detector) { described_class.new }

  describe "#initialize" do
    it "uses simple schema by default" do
      expect(detector.schema).to eq(ObsceneGpt::Prompts::SIMPLE_SCHEMA)
    end

    it "allows custom schema" do
      custom_schema = { type: "object", properties: { test: { type: "string" } } }
      detector = described_class.new(schema: custom_schema)
      expect(detector.schema).to eq(custom_schema)
    end
  end

  describe "#detect" do
    it "detects clean text correctly" do
      result = detector.detect("Hello, how are you today?")

      expect(result).to be_a(Hash)
      expect(result[:obscene]).to be false
      expect(result[:confidence]).to eq(0.95)
    end

    it "detects profanity patterns" do
      result = detector.detect("This is a fuck test")

      expect(result[:obscene]).to be true
      expect(result[:confidence]).to eq(0.85)
    end

    it "detects various profanity patterns" do
      profane_texts = [
        "This is fucked up",
        "I hate this",
        "Blood and gore",
        "Naked pictures",
        "Racist comments",
      ]

      profane_texts.each do |text|
        result = detector.detect(text)
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

      clean_texts.each do |text|
        result = detector.detect(text)
        expect(result[:obscene]).to be false
        expect(result[:confidence]).to eq(0.95)
      end
    end
  end

  describe "#detect_many" do
    it "detects multiple texts correctly" do
      results = detector.detect_many(["Hello", "This is shit", "Good morning"])

      expect(results).to be_an(Array)
      expect(results.length).to eq(3)
      expect(results[0][:obscene]).to be false
      expect(results[1][:obscene]).to be true
      expect(results[2][:obscene]).to be false
    end

    it "returns consistent results for same inputs" do
      texts = ["Test text", "Another test"]
      results1 = detector.detect_many(texts)
      results2 = detector.detect_many(texts)

      expect(results1).to eq(results2)
    end
  end

  describe "with full schema" do
    let(:detector) { described_class.new(schema: ObsceneGpt::Prompts::FULL_SCHEMA) }

    it "includes additional fields when using full schema" do
      result = detector.detect("This is a fuck test")

      expect(result[:obscene]).to be true
      expect(result[:confidence]).to eq(0.85)
      expect(result[:reasoning]).to eq("Contains inappropriate content")
      expect(result[:categories]).to eq(["profanity"])
    end

    it "includes clean text reasoning" do
      result = detector.detect("Hello, world!")

      expect(result[:obscene]).to be false
      expect(result[:confidence]).to eq(0.95)
      expect(result[:reasoning]).to eq("Clean text")
      expect(result[:categories]).to eq([])
    end

    it "handles multiple texts with full schema" do
      results = detector.detect_many(["Hello", "This is shit"])

      expect(results[0][:reasoning]).to eq("Clean text")
      expect(results[0][:categories]).to eq([])
      expect(results[1][:reasoning]).to eq("Contains inappropriate content")
      expect(results[1][:categories]).to eq(["profanity"])
    end
  end

  describe "pattern matching" do
    it "detects profanity variations" do
      profanity_variations = %w[
        fuck fucked fucking
        shit bitch ass damn hell
      ]

      profanity_variations.each do |word|
        result = detector.detect("This contains #{word}")
        expect(result[:obscene]).to be true
      end
    end

    it "detects sexual content" do
      sexual_content = %w[
        sex porn nude naked
      ]

      sexual_content.each do |word|
        result = detector.detect("This contains #{word}")
        expect(result[:obscene]).to be true
      end
    end

    it "detects violent content" do
      violent_content = %w[
        kill murder death blood gore
      ]

      violent_content.each do |word|
        result = detector.detect("This contains #{word}")
        expect(result[:obscene]).to be true
      end
    end

    it "detects hate speech" do
      hate_speech = %w[
        hate racist sexist
      ]

      hate_speech.each do |word|
        result = detector.detect("This contains #{word}")
        expect(result[:obscene]).to be true
      end
    end

    it "is case insensitive" do
      variations = %w[
        FUCK Fuck fUcK
        SHIT Shit sHiT
      ]

      variations.each do |word|
        result = detector.detect("This contains #{word}")
        expect(result[:obscene]).to be true
      end
    end

    it "requires word boundaries" do
      # These should NOT be detected as they're part of other words
      safe_words = [
        "suffer", "suffering",  # contains "fuck" but not as a word
        "shirt", "shirtless",   # contains "shit" but not as a word
        "assume", "assumption"  # contains "ass" but not as a word
      ]

      safe_words.each do |word|
        result = detector.detect("This contains #{word}")
        expect(result[:obscene]).to be false
      end
    end
  end
end
