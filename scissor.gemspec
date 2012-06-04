# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["youpy"]
  gem.email         = ["youpy@buycheapviagraonlinenow.com"]
  gem.description   = %q{utility to chop sound files}
  gem.summary       = %q{utility to chop sound files}
  gem.homepage      = %q{http://github.com/youpy/scissor}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = %q{scissor}
  gem.require_paths = ["lib"]
  gem.version       = "0.1.0"

  gem.add_dependency('open4', '>= 1.3.0')
  gem.add_dependency('ruby-mp3info')
  gem.add_dependency('riff', '<= 0.3.0')
  gem.add_dependency('tempdir')
  gem.add_dependency('streamio-ffmpeg')
  gem.add_development_dependency('rspec', ['~> 2.8.0'])
  gem.add_development_dependency('rake')
  gem.add_development_dependency('fakeweb')
end
