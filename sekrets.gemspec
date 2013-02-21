## sekrets.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "sekrets"
  spec.version = "1.0.1"
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
 "sekrets.gemspec",
 "test",
 "test/lib",
 "test/lib/testing.rb",
 "test/sekrets_test.rb"]

  spec.executables = ["sekrets"]
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["highline", " >= 1.6.15"])
  
    spec.add_dependency(*["map", " >= 6.3.0"])
  
    spec.add_dependency(*["fattr", " >= 2.2.1"])
  
    spec.add_dependency(*["coerce", " >= 0.0.3"])
  
    spec.add_dependency(*["main", " >= 5.1.1"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/sekrets"
end
