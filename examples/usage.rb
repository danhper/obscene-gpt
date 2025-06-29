require "obscene_gpt"

# Configure the gem globally (do this once in your app initialization)
ObsceneGpt.configure do |config|
  # config.api_key = "your-openai-api-key-here"
  config.model = "gpt-4.1-nano"
  config.schema = ObsceneGpt::Prompts::FULL_SCHEMA
end

detector = ObsceneGpt::Detector.new

texts_to_analyze = [
  "Hello, how are you today?",
  "This is a beautiful day!",
  "I love programming in Ruby.",
  "Some potentially inappropriate content here...",
  "This text contains explicit language and should be flagged.",
]

detector.detect_many(texts_to_analyze).each_with_index do |result, index|
  puts "Text: #{texts_to_analyze[index]}"
  puts "Obscene: #{result["obscene"]}"
  puts "Confidence: #{result["confidence"]}"
  puts "Reasoning: #{result["reasoning"]}"
  puts "Categories: #{result["categories"]}"
  puts "--------------------------------"
end
