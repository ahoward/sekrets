## sekrets.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "sekrets"
  spec.version = "1.10.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "sekrets"
  spec.description = "description: sekrets kicks the ass"
  spec.license = "Same as Ruby's" 

  spec.files =
["Gemfile",
 "Gemfile.lock",
 "README",
 "Rakefile",
 "bin",
 "bin/sekrets",
 "lib",
 "lib/sekrets",
 "lib/sekrets.rb",
 "lib/sekrets/capistrano.rb",
 "lib/sekrets/tasks",
 "lib/sekrets/tasks/capistrano2.rb",
 "lib/sekrets/tasks/sekrets.rake",
 "sekrets.gemspec",
 "test",
 "test/lib",
 "test/lib/testing.rb",
 "test/sekrets_test.rb"]

  spec.executables = ["sekrets"]
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["highline", " ~> 1.6"])
  
    spec.add_dependency(*["map", " ~> 6.3"])
  
    spec.add_dependency(*["fattr", " ~> 2.2"])
  
    spec.add_dependency(*["coerce", " >= 0.0.3"])
  
    spec.add_dependency(*["main", " ~> 6.1"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/sekrets"
end
