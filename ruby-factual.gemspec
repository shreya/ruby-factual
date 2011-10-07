# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-factual}
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Forrest Cao"]
  s.date = %q{2011-06-17}
  s.description = %q{Ruby gem to access Factual API}
  s.email = %q{sbhatia261@gmail.com}
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "lib/factual.rb"]
  s.homepage = %q{http://github.com/Factual/ruby-factual}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "ruby-factual", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.add_dependency('json', '>=1.2.0')
  s.test_files = ['test/unit/adapter.rb', 'test/unit/table.rb']
  s.summary = %q{}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
