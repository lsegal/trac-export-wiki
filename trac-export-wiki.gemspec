SPEC = Gem::Specification.new do |s|
  s.name          = "trac-export-wiki"
  s.summary       = "Exports Trac wiki pages as local HTML files." 
  s.description   = "Exports Trac wiki pages as local HTML files"
  s.version       = "1.0.1"
  s.date          = "2010-09-11"
  s.author        = "Loren Segal"
  s.email         = "lsegal@soen.ca"
  s.homepage      = "http://github.com/lsegal/trac-export-wiki"
  s.platform      = Gem::Platform::RUBY
  s.files         = Dir.glob("{bin,lib,spec,examples}/**/*") + ['LICENSE', 'README.md', 'Rakefile']
  s.require_paths = ['lib']
  s.executables   = ['trac-export-wiki']
  s.has_rdoc      = 'yard'
  s.rubyforge_project = 'trac-export-wiki'
  s.add_dependency 'hpricot'
end