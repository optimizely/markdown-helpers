Gem::Specification.new do |s|
  s.name        = "markdown-helpers"
  s.version     = "0.1.01"
  s.date        = "2015-10-30"
  s.summary     = "some helpers for working with github markdown"
  s.description = s.summary
  s.authors     = %w(Mike Wood)
  s.email       = "michael.wood@optimizely.com"
  s.homepage    = 'https://rubygems.org/gems/markdown-helpers'
  s.files       = Dir["lib/**/*.rb"]
  s.executables << 'markdownh'

  s.add_runtime_dependency "octokit", ">= 3.0"
  s.add_runtime_dependency "thor", "~> 0.19"
end
