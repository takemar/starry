require_relative 'lib/stella/version'

Gem::Specification.new do |s|
  s.name = 'stella'
  s.version = Stella::VERSION
  s.license = 'MIT'
  s.summary = 'An implementation of HTTP Structured Field Values (RFC 8941)'
  s.author = 'Takemaro'
  s.email = 'info@takemaro.com'
  s.files = Dir.glob('lib/**/*.rb')
  s.homepage = 'https://github.com/takemar/stella'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/takemar/stella/issues',
    'homepage_uri' => 'https://github.com/takemar/stella',
    'source_code_uri' => 'https://github.com/takemar/stella/issues',
  }
  s.required_ruby_version = '>= 2.7.0'
end
