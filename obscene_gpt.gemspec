require_relative "lib/obscene_gpt/version"

Gem::Specification.new do |spec|
  spec.name = "obscene_gpt"
  spec.version = ObsceneGpt::VERSION
  spec.authors = ["Daniel Perez"]
  spec.email = ["daniel@perez.sh"]

  spec.summary = "A Ruby gem that uses OpenAI API to detect obscene content in text"
  spec.description = "ObsceneGpt is a Ruby gem that integrates with OpenAI's API to detect whether given text contains obscene, inappropriate, or NSFW content. It provides a simple interface for content moderation using AI." # rubocop:disable Layout/LineLength
  spec.homepage = "https://github.com/danhper/obscene-gpt"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/danhper/obscene-gpt/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-openai", "~> 8.1"

  spec.metadata["rubygems_mfa_required"] = "true"
end
