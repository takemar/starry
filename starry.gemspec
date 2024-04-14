require_relative 'lib/starry/version'

Gem::Specification.new do |s|
  s.name = 'starry'
  s.version = Starry::VERSION
  s.license = 'MIT'
  s.summary = 'An implementation of HTTP Structured Field Values (RFC 8941)'
  s.author = 'Takemaro'
  s.email = 'info@takemaro.com'
  s.files = Dir.glob('lib/**/*.rb')
  s.homepage = 'https://github.com/takemar/starry'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/takemar/starry/issues',
    'homepage_uri' => 'https://github.com/takemar/starry',
    'source_code_uri' => 'https://github.com/takemar/starry',
  }
  s.required_ruby_version = '>= 2.7.0'
  s.add_runtime_dependency "base64"
end
