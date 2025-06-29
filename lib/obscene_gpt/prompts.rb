module ObsceneGpt
  module Prompts
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are a content moderation AI that analyzes texts for obscene, inappropriate, or NSFW content.

      Your task is to determine if the given text contains:
      - Explicit sexual content
      - Profanity or vulgar language
      - Hate speech or discriminatory language
      - Violent or graphic content
      - Other inappropriate material

      You will be given a JSON array of texts.
      You will need to analyze each text and determine if it contains any of the above content.
    PROMPT

    SIMPLE_SCHEMA = {
      type: "object",
      properties: {
        obscene: {
          type: "boolean",
          description: "Whether the text contains obscene content",
        },
        confidence: {
          type: "number",
          minimum: 0,
          maximum: 1,
          description: "A confidence score between 0 and 1",
        },
      },
      required: %w[obscene confidence],
      additionalProperties: false,
    }.freeze

    FULL_SCHEMA = {
      type: "object",
      properties: SIMPLE_SCHEMA[:properties].merge(
        reasoning: {
          type: "string",
          description: "A reasoning for the classification",
        },
        categories: {
          type: "array",
          items: { type: "string", enum: %w[sexual profanity hate violent other] },
          description: "A list of categories that the text belongs to",
        },
      ),
      required: %w[obscene confidence reasoning categories],
      additionalProperties: false,
    }.freeze
  end
end
