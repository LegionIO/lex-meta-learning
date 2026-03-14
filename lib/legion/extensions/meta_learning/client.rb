# frozen_string_literal: true

require 'legion/extensions/meta_learning/helpers/constants'
require 'legion/extensions/meta_learning/helpers/learning_domain'
require 'legion/extensions/meta_learning/helpers/strategy'
require 'legion/extensions/meta_learning/helpers/meta_learning_engine'
require 'legion/extensions/meta_learning/runners/meta_learning'

module Legion
  module Extensions
    module MetaLearning
      class Client
        include Runners::MetaLearning

        private

        def engine
          @engine ||= Helpers::MetaLearningEngine.new
        end
      end
    end
  end
end
