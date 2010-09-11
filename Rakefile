require 'rbconfig'

WINDOWS = (Config::CONFIG['host_os'] =~ /mingw|win32|cygwin/ ? true : false) rescue false
SUDO = WINDOWS ? '' : 'sudo'

task :default => :specs

desc "Builds the gem"
task :gem do
  load 'trac-export-wiki.gemspec'
  Gem::Builder.new(SPEC).build
end

desc "Installs the gem"
task :install => :gem do 
  sh "#{SUDO} gem install #{SPEC.full_name}.gem --no-rdoc --no-ri"
end

begin
  require 'spec'
  require 'spec/rake/spectask'

  desc "Run all specs"
  Spec::Rake::SpecTask.new("specs") do |t|
    $DEBUG = true if ENV['DEBUG']
    t.spec_opts = ["--format", "specdoc", "--colour"]
    t.spec_opts += ["--require", File.join(File.dirname(__FILE__), 'spec', 'spec_helper')]
    t.spec_files = Dir["spec/**/*_spec.rb"].sort
  end
  task :spec => :specs
rescue LoadError
  warn "warn: RSpec tests not available. `gem install rspec` to enable them."
end
