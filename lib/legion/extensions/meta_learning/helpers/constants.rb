# frozen_string_literal: true

module Legion
  module Extensions
    module MetaLearning
      module Helpers
        module Constants
          MAX_DOMAINS    = 100
          MAX_STRATEGIES = 50
          MAX_EPISODES   = 1000

          DEFAULT_LEARNING_RATE = 0.1
          RATE_BOOST            = 0.02
          RATE_DECAY            = 0.01
          TRANSFER_BONUS        = 0.05

          PROFICIENCY_LABELS = {
            (0.8..)     => :expert,
            (0.6...0.8) => :proficient,
            (0.4...0.6) => :intermediate,
            (0.2...0.4) => :novice,
            (..0.2)     => :beginner
          }.freeze

          EFFICIENCY_LABELS = {
            (0.8..)     => :highly_efficient,
            (0.6...0.8) => :efficient,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :slow,
            (..0.2)     => :struggling
          }.freeze

          STRATEGY_TYPES = %i[
            repetition elaboration analogy decomposition
            pattern_matching trial_and_error observation
            interleaving spaced_practice retrieval_practice
          ].freeze
        end
      end
    end
  end
end
