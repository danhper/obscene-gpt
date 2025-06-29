require "spec_helper"

RSpec.describe ObsceneContentValidator do
  before do
    # Reset configuration before each test to prevent interference
    ObsceneGpt.instance_variable_set(:@configuration, nil)

    # Mock the ObsceneGpt.detect_many method
    allow(ObsceneGpt).to receive(:detect_many).and_return([])
  end

  # Create a test model class for testing the validator
  let(:test_model_class) do
    # Give the class a name for ActiveModel::Errors
    stub_const("TestModel", Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      attribute :title, :string
      attribute :content, :string
      attribute :description, :string

      def read_attribute_for_validation(attr)
        send(attr)
      end

      def errors
        @errors ||= ActiveModel::Errors.new(self)
      end
    end)
  end

  let(:record) { test_model_class.new }

  describe "#validate" do
    context "when attributes are clean" do
      before do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: false, confidence: 0.95,
              reasoning: "Clean content" },
            { obscene: false, confidence: 0.98,
              reasoning: "Appropriate text" },
          ],
        )

        test_model_class.validates :title, :content, obscene_content: true
        record.title = "Hello World"
        record.content = "This is a test"
      end

      it "does not add errors for clean content" do
        validator = ObsceneContentValidator.new(attributes: %i[title content])
        validator.validate(record)

        expect(record.errors).to be_empty
      end

      it "calls ObsceneGpt.detect_many with prepared values" do
        validator = ObsceneContentValidator.new(attributes: %i[title content])

        expect(ObsceneGpt).to receive(:detect_many).with(["Hello World", "This is a test"])

        validator.validate(record)
      end
    end

    context "when attributes contain obscene content" do
      before do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: true, confidence: 0.85,
              reasoning: "Contains inappropriate language" },
            { obscene: false, confidence: 0.95,
              reasoning: "Clean content" },
          ],
        )

        test_model_class.validates :title, :content, obscene_content: true
        record.title = "Bad title"
        record.content = "This is clean"
      end

      it "adds errors for obscene content" do
        validator = ObsceneContentValidator.new(attributes: %i[title content])
        validator.validate(record)

        expect(record.errors[:title]).to include("Contains inappropriate language")
        expect(record.errors[:content]).to be_empty
      end

      it "uses custom reasoning when available" do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: true, confidence: 0.85,
              reasoning: "Contains profanity" },
          ],
        )

        validator = ObsceneContentValidator.new(attributes: [:title])
        validator.validate(record)

        expect(record.errors[:title]).to include("Contains profanity")
      end
    end

    context "with custom threshold" do
      before do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: true, confidence: 0.7,
              reasoning: "Somewhat inappropriate" },
          ],
        )

        test_model_class.validates :title, obscene_content: { threshold: 0.8 }
        record.title = "Questionable title"
      end

      it "respects custom threshold" do
        validator = ObsceneContentValidator.new(attributes: [:title], options: { threshold: 0.8 })
        validator.validate(record)

        # Should not add error because confidence (0.7) < threshold (0.8)
        expect(record.errors[:title]).to be_empty
      end

      it "adds error when confidence exceeds threshold" do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: true, confidence: 0.9,
              reasoning: "Very inappropriate" },
          ],
        )

        validator = ObsceneContentValidator.new(attributes: [:title], options: { threshold: 0.8 })
        validator.validate(record)

        expect(record.errors[:title]).to include("Very inappropriate")
      end
    end

    context "with per-attribute custom thresholds" do
      before do
        test_model_class.validates :title, obscene_content: true
        test_model_class.validates :content, obscene_content: true
        record.title = "Questionable title"
        record.content = "Questionable content"
      end

      it "uses different thresholds for different attributes" do
        # Mock different results for each attribute
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: true, confidence: 0.75, reasoning: "Somewhat inappropriate title" },
            { obscene: true, confidence: 0.85, reasoning: "More inappropriate content" },
          ],
        )

        # Create validator with per-attribute thresholds
        validator = ObsceneContentValidator.new(
          attributes: %i[title content],
          options: {
            title: { threshold: 0.8 }, # title needs 0.8+ confidence
            content: { threshold: 0.7 }, # content needs 0.7+ confidence
          },
        )

        validator.validate(record)

        # title should not have error (0.75 < 0.8)
        expect(record.errors[:title]).to be_empty
        # content should have error (0.85 >= 0.7)
        expect(record.errors[:content]).to include("More inappropriate content")
      end

      it "falls back to global threshold when per-attribute threshold is not set" do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: true, confidence: 0.75, reasoning: "Somewhat inappropriate title" },
            { obscene: true, confidence: 0.75, reasoning: "Somewhat inappropriate content" },
          ],
        )

        # Create validator with only global threshold
        validator = ObsceneContentValidator.new(
          attributes: %i[title content],
          options: { threshold: 0.8 }, # global threshold
        )

        validator.validate(record)

        # Both should not have errors (both < 0.8)
        expect(record.errors[:title]).to be_empty
        expect(record.errors[:content]).to be_empty
      end

      it "falls back to configuration default when no threshold is set" do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: true, confidence: 0.75, reasoning: "Somewhat inappropriate title" },
          ],
        )

        # Mock configuration default threshold
        allow(ObsceneGpt.configuration).to receive(:profanity_threshold).and_return(0.7)

        validator = ObsceneContentValidator.new(attributes: [:title])
        validator.validate(record)

        # Should have error (0.75 >= 0.7)
        expect(record.errors[:title]).to include("Somewhat inappropriate title")
      end
    end

    context "with nil and blank values" do
      before do
        test_model_class.validates :title, :content, :description, obscene_content: true
        record.title = nil
        record.content = ""
        record.description = "   "
      end

      it "skips nil and blank values" do
        validator = ObsceneContentValidator.new(attributes: %i[title content description])

        # Should not call detect_many since all values are nil/blank
        expect(ObsceneGpt).not_to receive(:detect_many)

        validator.validate(record)
        expect(record.errors).to be_empty
      end
    end

    context "with mixed nil/blank and valid values" do
      before do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: false, confidence: 0.95,
              reasoning: "Clean content" },
          ],
        )

        test_model_class.validates :title, :content, :description, obscene_content: true
        record.title = nil
        record.content = "Valid content"
        record.description = ""
      end

      it "only validates non-nil, non-blank values" do
        validator = ObsceneContentValidator.new(attributes: %i[title content description])

        expect(ObsceneGpt).to receive(:detect_many).with(["Valid content"])

        validator.validate(record)
        expect(record.errors).to be_empty
      end
    end

    context "when ObsceneGpt.detect_many raises an error" do
      before do
        allow(ObsceneGpt).to receive(:detect_many).and_raise(StandardError.new("API Error"))
        test_model_class.validates :title, obscene_content: true
        record.title = "Test content"
      end

      it "allows the error to bubble up" do
        validator = ObsceneContentValidator.new(attributes: [:title])

        expect { validator.validate(record) }.to raise_error(StandardError, "API Error")
      end
    end
  end

  describe "integration with ActiveModel" do
    let(:model_with_validator) do
      stub_const("IntegrationModel", Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModel::Validations

        attribute :title, :string
        attribute :content, :string

        validates :title, obscene_content: true
        validates :content, obscene_content: { threshold: 0.9 }

        def read_attribute_for_validation(attr)
          send(attr)
        end
      end)
    end

    it "works with ActiveModel validations" do
      # Each validates call creates a separate validator instance
      # So we need to mock detect_many for each call
      allow(ObsceneGpt).to receive(:detect_many).and_return(
        [
          { obscene: true, confidence: 0.85, reasoning: "Inappropriate title" },
        ], [
          { obscene: true, confidence: 0.95, reasoning: "Very inappropriate content" },
        ]
      )

      record = model_with_validator.new(title: "Bad title", content: "Bad content")

      expect(record).not_to be_valid
      expect(record.errors[:title]).to include("Inappropriate title")
      expect(record.errors[:content]).to include("Very inappropriate content")
    end

    it "passes validation when content is clean" do
      allow(ObsceneGpt).to receive(:detect_many).and_return(
        [
          { obscene: false, confidence: 0.95, reasoning: "Clean title" },
        ], [
          { obscene: false, confidence: 0.98, reasoning: "Clean content" },
        ]
      )

      record = model_with_validator.new(title: "Good title", content: "Good content")

      expect(record).to be_valid
      expect(record.errors).to be_empty
    end
  end

  describe "edge cases" do
    context "with empty attributes array" do
      it "raises ArgumentError for empty attributes" do
        expect { ObsceneContentValidator.new(attributes: []) }.to raise_error(ArgumentError)
      end
    end

    context "with non-string values" do
      before do
        test_model_class.validates :title, obscene_content: true
        record.title = 123
      end

      it "converts non-string values to strings" do
        validator = ObsceneContentValidator.new(attributes: [:title])

        expect(ObsceneGpt).to receive(:detect_many).with(["123"])

        validator.validate(record)
      end
    end

    context "with very long content" do
      before do
        test_model_class.validates :content, obscene_content: true
        record.content = "a" * 10_000
      end

      it "handles long content" do
        allow(ObsceneGpt).to receive(:detect_many).and_return(
          [
            { obscene: false, confidence: 0.95,
              reasoning: "Long but clean content" },
          ],
        )

        validator = ObsceneContentValidator.new(attributes: [:content])

        expect { validator.validate(record) }.not_to raise_error
        expect(record.errors).to be_empty
      end
    end
  end
end
