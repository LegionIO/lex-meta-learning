# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module MetaLearning
      module Helpers
        class LearningDomain
          include Constants

          attr_accessor :preferred_strategy
          attr_reader :id, :name, :proficiency, :learning_rate, :episodes_count, :successes, :failures, :related_domains, :created_at

          def initialize(name:, learning_rate: DEFAULT_LEARNING_RATE, related_domains: [])
            @id               = SecureRandom.uuid
            @name             = name
            @proficiency      = 0.0
            @learning_rate    = learning_rate.clamp(0.001, 1.0)
            @episodes_count   = 0
            @successes        = 0
            @failures         = 0
            @preferred_strategy = nil
            @related_domains  = Array(related_domains).dup
            @created_at       = Time.now.utc
          end

          def record_success!
            @successes      += 1
            @episodes_count += 1
            @proficiency     = (@proficiency + @learning_rate).clamp(0.0, 1.0).round(10)
          end

          def record_failure!
            @failures       += 1
            @episodes_count += 1
            penalty          = (@learning_rate * 0.5).round(10)
            @proficiency     = (@proficiency - penalty).clamp(0.0, 1.0).round(10)
          end

          def efficiency
            total = @successes + @failures
            return 0.0 if total.zero?

            (@successes.to_f / total).round(10)
          end

          def efficiency_label
            EFFICIENCY_LABELS.find { |range, _| range.cover?(efficiency) }&.last || :struggling
          end

          def proficiency_label
            PROFICIENCY_LABELS.find { |range, _| range.cover?(@proficiency) }&.last || :beginner
          end

          def adapt_rate!(delta:)
            @learning_rate = (@learning_rate + delta).clamp(0.001, 1.0).round(10)
          end

          def to_h
            {
              id:                 @id,
              name:               @name,
              proficiency:        @proficiency,
              proficiency_label:  proficiency_label,
              learning_rate:      @learning_rate,
              episodes_count:     @episodes_count,
              successes:          @successes,
              failures:           @failures,
              efficiency:         efficiency,
              efficiency_label:   efficiency_label,
              preferred_strategy: @preferred_strategy,
              related_domains:    @related_domains,
              created_at:         @created_at
            }
          end
        end
      end
    end
  end
end
