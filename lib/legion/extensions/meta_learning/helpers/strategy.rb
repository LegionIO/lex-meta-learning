# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module MetaLearning
      module Helpers
        class Strategy
          include Constants

          attr_reader :id, :name, :strategy_type, :usage_count,
                      :success_count, :domains_used, :created_at

          def initialize(name:, strategy_type:)
            @id             = SecureRandom.uuid
            @name           = name
            @strategy_type  = strategy_type
            @usage_count    = 0
            @success_count  = 0
            @domains_used   = []
            @created_at     = Time.now.utc
          end

          def use!(success:, domain_name: nil)
            @usage_count += 1
            @success_count += 1 if success
            @domains_used << domain_name if domain_name && !@domains_used.include?(domain_name)
          end

          def success_rate
            return 0.0 if @usage_count.zero?

            (@success_count.to_f / @usage_count).round(10)
          end

          def versatility
            @domains_used.uniq.size
          end

          def to_h
            {
              id:            @id,
              name:          @name,
              strategy_type: @strategy_type,
              usage_count:   @usage_count,
              success_count: @success_count,
              success_rate:  success_rate,
              versatility:   versatility,
              domains_used:  @domains_used,
              created_at:    @created_at
            }
          end
        end
      end
    end
  end
end
