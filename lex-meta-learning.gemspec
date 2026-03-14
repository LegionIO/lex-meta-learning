# frozen_string_literal: true

require_relative 'lib/legion/extensions/meta_learning/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-meta-learning'
  spec.version       = Legion::Extensions::MetaLearning::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Meta-Learning'
  spec.description   = 'Meta-learning engine for brain-modeled agentic AI — tracks learning efficiency, ' \
                       'adapts learning rates, and selects strategies based on past performance'
  spec.homepage      = 'https://github.com/LegionIO/lex-meta-learning'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-meta-learning'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-meta-learning'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-meta-learning'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-meta-learning/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-meta-learning.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
