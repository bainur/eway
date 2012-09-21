# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{eway}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{bainur}]
  s.date = %q{2011-08-11}
  s.description = %q{Eway payment Api}
  s.email = %q{inoe.bainur@gmail.com}
  s.extra_rdoc_files = [%q{README.rdoc}, %q{lib/eway.rb}]
  s.files = [%q{README.rdoc}, %q{Rakefile}, %q{lib/eway.rb}, %q{Manifest}, %q{eway.gemspec}]
  s.homepage = %q{http://github.com/bainur/eway}
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{eway}, %q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{ewat}
  s.rubygems_version = %q{1.9.2}
  s.summary = %q{Eway Api}
  s.add_dependency 'nokogiri', '1.5.5'
  s.add_dependency 'rest-client', '1.6.7'
  s.add_dependency 'savon', '1.2.0'
  s.add_dependency 'activemerchant', '1.28.0'

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
