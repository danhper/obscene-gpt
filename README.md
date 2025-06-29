# ObsceneGpt

A Ruby gem that integrates with OpenAI's API to detect whether given text contains obscene, inappropriate, or NSFW content. It provides a simple interface for content moderation using AI.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'obscene_gpt'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install obscene_gpt
```

## Setup

You'll need an OpenAI API key to use this gem. You can either:

1. Set it as an environment variable:
```bash
export OPENAI_API_KEY="your-openai-api-key-here"
```

2. Configure it globally in your application (recommended):
```ruby
ObsceneGpt.configure do |config|
  config.api_key = "your-openai-api-key-here"
  config.model = "gpt-4.1-nano"
end
```

3. Pass it directly when instantiating the detector

```ruby
detector = ObsceneGpt::Detector.new(api_key: "your-openai-api-key-here")
```

## Usage

### Basic Usage

```ruby
require 'obscene_gpt'

# Configure once in your app initialization
ObsceneGpt.configure do |config|
  config.api_key = "your-openai-api-key-here"
  config.model = "gpt-4.1-nano"
end

detector = ObsceneGpt::Detector.new

result = detector.detect("Hello, how are you today?")
puts result
# => {"obscene" => false, "confidence" => 0.95, "reasoning" => "The text is a polite greeting with no inappropriate content.", "categories" => []}

result = detector.detect("Some offensive text with BAAD words")
puts result
# => {"obscene" => true, "confidence" => 0.85, "reasoning" => "The text contains vulgar language with the word 'BAAD', which is likely intended as a vulgar or inappropriate term.", "categories" => ["profanity"]}
```

### ActiveModel Validator

When ActiveModel is available, you can use the built-in validator to automatically check for obscene content in your models:

```ruby
class Post < ActiveRecord::Base
  validates :content, obscene_content: true
  validates :title, obscene_content: { message: "Title contains inappropriate language" }
end

# The validator automatically caches results to avoid duplicate API calls
post = Post.new(content: "Some potentially inappropriate content")
if post.valid?
  puts "Post is valid"
else
  puts "Validation errors: #{post.errors.full_messages}"
end
```

**Important:** The validator uses Rails caching to ensure only one API call is made per unique text content. Results are cached for 1 hour to avoid repeated API calls for the same content.

## API Reference

### Configuration

#### ObsceneGpt.configure(&block)

Configure the gem globally.

```ruby
ObsceneGpt.configure do |config|
  config.api_key = "your-api-key"
  config.model = "gpt-4.1-nano"
  config.schema = ObsceneGpt::Prompts::SIMPLE_SCHEMA
  config.prompt = ObsceneGpt::Prompts::SYSTEM_PROMPT
end
```

#### ObsceneGpt.configuration

Get the current configuration object.

### ObsceneGpt::Detector

#### ObsceneGpt::Detector.new(api_key: nil, model: nil)

Creates a new detector instance.

#### ObsceneGpt::Detector#detect(text)

Detects whether the given text contains obscene content.

**Parameters:**
- `text` (String): Text to analyze.

**Returns:** Hash with detection results. See `Response Format` for more details.

**Raises:**
- `ObsceneGpt::Error`: If there's an OpenAI API error

#### ObsceneGpt::Detector#detect_many(texts)

Detects whether the given texts contain obscene content.

**Parameters:**
- `texts` (Array<String>): Texts to analyze.

**Returns:** Array of hashes with detection results. See `Response Format` for more details.

**Raises:**
- `ObsceneGpt::Error`: If there's an OpenAI API error

### ObsceneGpt::ObsceneContentValidator

**Note:** This validator is only available when ActiveRecord is loaded.

A custom ActiveRecord validator that checks whether a field contains obscene content.

#### Usage

```ruby
class Post < ActiveRecord::Base
  validates :content, obscene_content: true
  validates :title, obscene_content: { message: "Custom error message" }
end
```

#### Options

- `message` (String): Custom error message to display when validation fails. Default: "contains inappropriate content"

#### Features

- **Caching:** Automatically caches results using Rails cache to avoid duplicate API calls for the same content
- **Cache Duration:** Results are cached for 1 hour
- **Error Handling:** Gracefully handles cache and API errors without failing validation
- **Performance:** Only makes one API call per unique text content

## Response Format

The detection methods return a hash (or array of hashes) with the following structure:

```ruby
{
  obscene: true,                    # Boolean: whether content is inappropriate
  confidence: 0.85,                # Float: confidence score (0.0-1.0)
  reasoning: "Contains explicit language and profanity",
  categories: ["profanity", "explicit"]  # Array of detected categories (["sexual", "profanity", "hate", "violent", "other"])
}
```

## Configuration Options

### Default options

The default configuration is:

```ruby
config.api_key = ENV["OPENAI_API_KEY"]
config.model = "gpt-4.1-nano"
config.schema = ObsceneGpt::Prompts::SIMPLE_SCHEMA
config.prompt = ObsceneGpt::Prompts::SYSTEM_PROMPT
```

### Model

We recommend using the `gpt-4.1-nano` model for cost efficiency.
Given the simplicity of the task, it's typically not necessary to use a more expensive model.

See [OpenAI's documentation](https://platform.openai.com/docs/pricing) for more information.

### Prompt

The system prompt can be found in `lib/obscene_gpt/prompts.rb`.
This is a basic prompt that can be used to detect obscene content.
You can use a custom prompt if you need to by setting the `prompt` option in the configuration.

### Schema

This library uses a JSON schema to enforce the response from the OpenAI API.
There are two schemas available:

- `ObsceneGpt::Prompts::SIMPLE_SCHEMA`: A simple schema that only includes the `obscene` and `confidence` fields.
- `ObsceneGpt::Prompts::FULL_SCHEMA`: A full schema that includes the `obscene`, `confidence`, `reasoning`, and `categories` fields.

You can use a custom schema if you need to by setting the `schema` option in the configuration.

### Configuration Precedence

1. Explicit parameters passed to methods
2. Global configuration
3. Environment variables (for API key only)

## Examples

See the `examples/usage.rb` file for usage examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danhper/obscene_gpt.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
