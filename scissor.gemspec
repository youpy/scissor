Gem::Specification.new do |s|
  s.name = %q{scissor}
  s.version = "0.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["youpy"]
  s.date = %q{2009-04-05}
  s.description = %q{utility to chop mp3 files}
  s.email = %q{youpy@buycheapviagraonlinenow.com}
  s.extra_rdoc_files = ["README.rdoc", "ChangeLog"]
  s.files = ["README.rdoc", "ChangeLog", "Rakefile", "lib/scissor.rb", "data/silence.mp3"]
  s.has_rdoc = true
  s.homepage = %q{http://scissor.rubyforge.org}
  s.rdoc_options = ["--title", "scissor documentation", "--charset", "utf-8", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{scissor}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{utility to chop mp3 files}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<ruby-mp3info>, [">= 0"])
    else
      s.add_dependency(%q<ruby-mp3info>, [">= 0"])
    end
  else
    s.add_dependency(%q<ruby-mp3info>, [">= 0"])
  end
end
