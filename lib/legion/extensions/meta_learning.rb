# frozen_string_literal: true

require 'legion/extensions/meta_learning/version'
require 'legion/extensions/meta_learning/helpers/constants'
require 'legion/extensions/meta_learning/helpers/learning_domain'
require 'legion/extensions/meta_learning/helpers/strategy'
require 'legion/extensions/meta_learning/helpers/meta_learning_engine'
require 'legion/extensions/meta_learning/runners/meta_learning'
require 'legion/extensions/meta_learning/client'

module Legion
  module Extensions
    module MetaLearning
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
