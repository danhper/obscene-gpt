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

See the `examples/usage.rb` file for usage examples.

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
  validates :description, obscene_content: { threshold: 0.9 }
  validates :comment, obscene_content: {
    threshold: 0.8,
    message: "Comment violates community guidelines"
  }
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

## Important considerations

### Cost

The cost of using this gem is based on the number of API calls made.
A very short input text will have roughly 170 tokens, and each 200 characters adds roughly another 50 tokens.
The simple schema has 17 output tokens and the full schema has ~50 (depending on the length of the reasoning and the attributes).
Using the simple schema and with an average of 200 chars per request, the cost (with the gpt-4.1-nano model) is roughly $1 per 35,000 requests.

### Rate limits

The OpenAI API has rate limits that depends on the model you are using.
The gpt-4.1-nano model has a rate limit of 500 requests per minute with a normal paid subscription.

### Latency

Calling an API will obviously add some latency to your application.
The latency is dependent on the model you are using and the length of the text you are analyzing.
We do not recommend using this gem in latency-sensitive application.

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
config.test_mode = false
config.test_detector_class = ObsceneGpt::TestDetector
```

### Test Mode

To avoid making API calls during testing, you can enable test mode:

```ruby
ObsceneGpt.configure do |config|
  config.test_mode = true
end
```

When test mode is enabled, the detector will return mock responses based on simple pattern matching instead of making actual API calls. This is useful for:

- Running tests without API costs
- Faster test execution
- Avoiding rate limits during development

**Note:** Test mode uses basic pattern matching and is not as accurate as the actual AI model. It's intended for testing purposes only.

#### Custom Test Detectors

You can also configure a custom test detector class for more sophisticated test behavior:

```ruby
class MyCustomTestDetector
  attr_reader :schema

  def initialize(schema: nil)
    @schema = schema || ObsceneGpt::Prompts::SIMPLE_SCHEMA
  end

  def detect_many(texts)
    texts.map do |text|
      {
        obscene: text.include?("bad_word"),
        confidence: 0.9
      }
    end
  end

  def detect(text)
    detect_many([text])[0]
  end
end

ObsceneGpt.configure do |config|
  config.test_mode = true
  config.test_detector_class = MyCustomTestDetector
end
```

Custom test detectors must implement:

- `#initialize(schema: nil)` - Accepts an optional schema parameter
- `#detect_many(texts)` - Returns an array of result hashes

See `examples/custom_test_detector.rb` for more examples.

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

## ActiveModel Integration

The `ObsceneContentValidator` is available when ActiveModel is loaded.
`active_model` needs to be required before obscene_gpt.

### Usage

```ruby
class Post < ActiveRecord::Base
  validates :content, :title, :description, obscene_content: true
end
```

**Note**: Each instance of this validator will make a request to the OpenAI API.
Therefore, it is recommended to pass all the attributes you want to check to the validator at once as shown above.

### Options

- `threshold` (Float): Custom confidence threshold (0.0-1.0) for determining when content is considered inappropriate. Default: Uses `ObsceneGpt.configuration.profanity_threshold`
- `message` (String): Custom error message to display when validation fails. Default: Uses AI reasoning if available, otherwise "contains inappropriate content"

### Per-Attribute Options

You can also configure different options for different attributes in a single validation call:

```ruby
class Post < ActiveRecord::Base
  validates :title, :content, obscene_content: {
    title: { threshold: 0.8, message: "Title is too inappropriate" },
    content: { threshold: 0.7, message: "Content needs moderation" }
  }
end
```

### Configuration Precedence

The validator uses the following precedence for options:

**Threshold:**

1. Per-attribute option (e.g., `title: { threshold: 0.8 }`)
2. Validator option (e.g., `threshold: 0.8`)
3. Configuration default (`ObsceneGpt.configuration.profanity_threshold`)

**Message:**

1. Per-attribute message (e.g., `title: { message: "..." }`)
2. Global message (e.g., `message: "..."`)
3. AI reasoning (if available, only when schema is `ObsceneGpt::Prompts::FULL_SCHEMA`)
4. Default message ("contains inappropriate content")

### Examples

**Basic validation:**

```ruby
class Post < ActiveRecord::Base
  validates :content, obscene_content: true
end
```

**With custom message:**

```ruby
class Post < ActiveRecord::Base
  validates :title, obscene_content: { message: "Title contains inappropriate content" }
end
```

**With custom threshold:**

```ruby
class Post < ActiveRecord::Base
  validates :description, obscene_content: { threshold: 0.9 }
end
```

**With both custom threshold and message:**

```ruby
class Post < ActiveRecord::Base
  validates :comment, obscene_content: {
    threshold: 0.8,
    message: "Comment violates community guidelines"
  }
end
```

**Per-attribute configuration:**

```ruby
class Post < ActiveRecord::Base
  validates :title, :content, obscene_content: {
    title: { threshold: 0.8, message: "Title is too inappropriate" },
    content: { threshold: 0.7, message: "Content needs moderation" }
  }
end
```

**Mixed global and per-attribute options:**

```ruby
class Post < ActiveRecord::Base
  validates :title, :content, obscene_content: {
    threshold: 0.8,  # Global threshold
    message: "Contains inappropriate content",  # Global message
    title: { threshold: 0.9 }  # Override threshold for title only
  }
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danhper/obscene_gpt.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
