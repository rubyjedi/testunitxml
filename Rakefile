#require 'fileutils'
require 'rubygems'
Gem::manage_gems
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rdoc/rdoc'

#include FileUtils::DryRun

PROJECT_NAME = "TestUnitXML"

SRC = FileList["README", "MIT-LICENSE", "lib/**/*.rb"]
CLOBBER << FileList["docs/html"]

desc "Generate documentation"
task :rdoc => [:clobber, :test]do
  begin
    r = RDoc::RDoc.new
    args = %W[-o docs/html -m #{SRC[0]} -T html] + SRC
    r.document(args)
  rescue RDoc::RDocError => e
    $stderr.puts e.message
  end
end

# Create a task named 'test'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb']
  t.verbose = true
end



# Add a task for creating GEM packages
spec = Gem::Specification.new do |s|
  s.name    = PROJECT_NAME
  s.version = "0.1.2"
  s.author  = "Henrik Martensson"
  s.email   = "self@henrikmartensson.org"
  s.homepage = "http://www.henrik.vrensk.com/downloads/ruby/testunitxml.html"
  s.platform = Gem::Platform::RUBY
  s.summary   = "Unit test suite for XML documents"
  s.files     = FileList["{bin,docs,lib,test}/**/*"].exclude("rdoc").to_a
  s.require_path = "lib"
  s.autorequire  = "testunitxml"
  s.test_file    = "test/tc_testunitxml.rb"
  s.has_rdoc     = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency("REXML", " >= 1.3.1")
#  s.add_dependency("xmlutil")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
