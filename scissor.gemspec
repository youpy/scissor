Gem::Specification.new do |s|
  s.name = %q{scissor}
  s.version = "0.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["youpy"]
  s.date = %q{2009-04-06}
  s.description = %q{utility to chop sound files}
  s.email = %q{youpy@buycheapviagraonlinenow.com}
  s.extra_rdoc_files = ["README.rdoc", "ChangeLog"]
  s.files = ["README.rdoc", "ChangeLog", "Rakefile", "lib/scissor", "lib/scissor/chunk.rb", "lib/scissor/fragment.rb", "lib/scissor/sequence.rb", "lib/scissor/sound_file.rb", "lib/scissor.rb", "data/silence.mp3"]
  s.has_rdoc = true
  s.homepage = %q{http://scissor.rubyforge.org}
  s.rdoc_options = ["--title", "scissor documentation", "--charset", "utf-8", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{scissor}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{utility to chop sound files}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<open4>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-mp3info>, [">= 0"])
      s.add_runtime_dependency(%q<riff>, [">= 0"])
    else
      s.add_dependency(%q<open4>, [">= 0"])
      s.add_dependency(%q<ruby-mp3info>, [">= 0"])
      s.add_dependency(%q<riff>, [">= 0"])
    end
  else
    s.add_dependency(%q<open4>, [">= 0"])
    s.add_dependency(%q<ruby-mp3info>, [">= 0"])
    s.add_dependency(%q<riff>, [">= 0"])
  end
end
