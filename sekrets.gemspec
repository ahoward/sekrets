## sekrets.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "sekrets"
  spec.version = "0.4.2"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "sekrets"
  spec.description = "description: sekrets kicks the ass"

  spec.files =
["README",
 "Rakefile",
 "bin",
 "bin/sekrets",
 "lib",
 "lib/sekrets",
 "lib/sekrets.rb",
 "lib/sekrets/capistrano.rb",
 "test",
 "test/lib",
 "test/lib/testing.rb",
 "test/sekrets_test.rb"]

  spec.executables = ["sekrets"]
  
  spec.require_path = "lib"

  spec.test_files = nil

### spec.add_dependency 'lib', '>= version'
#### spec.add_dependency 'map'

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/sekrets"
end
