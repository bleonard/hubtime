# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hubtime/version"

Gem::Specification.new do |s|
  s.name        = "hubtime"
  s.version     = Hubtime::VERSION
  s.summary     = "Visualization of your Github activity over the past year via Github API."
  s.email       = "contact@plataformatec.com.br"
  s.homepage    = "http://github.com/bleonard/hubtime"
  s.description = "Visualization of your Github activity over the past year via Github API with visualizations like table, graph, stacked graph and pie chart."
  s.authors     = ['Brian Leonard']

  s.rubyforge_project = "hubtime"

  s.executables << "hubtime"
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency("activesupport", "~> 3.0")
  s.add_dependency("commander", "~> 4.1")
  s.add_dependency("i18n", "~> 0.6")
  s.add_dependency("tzinfo", "~> 0.3")
  s.add_dependency("octokit", "~> 1.20")
  s.add_dependency("terminal-table", "~> 1.4")
  s.add_dependency("erubis", "~> 2.7")
end
