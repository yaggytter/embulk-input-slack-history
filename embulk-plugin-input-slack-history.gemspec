
Gem::Specification.new do |gem|
  gem.name          = "embulk-plugin-input-slack-history"
  gem.version       = "0.0.1"

  gem.summary       = %q{Embulk input plugin for Slack chat history}
  gem.description   = gem.summary
  gem.authors       = ["Akihiro YAGASAKI"]
  gem.email         = ["yaggytter@momiage.com"]
  gem.license       = "Apache 2.0"
  gem.homepage      = "https://github.com/yaggytter/embulk-plugin-input-slack-history"

  gem.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.has_rdoc      = false

  gem.add_dependency 'rest-client', ['>= 1.7.2']
  gem.add_development_dependency 'bundler', ['~> 1.0']
  gem.add_development_dependency 'rake', ['>= 0.9.2']
end
