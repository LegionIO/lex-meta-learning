# frozen_string_literal: true

module Legion
  module Extensions
    module MetaLearning
      module Runners
        module MetaLearning
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_learning_domain(name:, learning_rate: Helpers::Constants::DEFAULT_LEARNING_RATE,
                                     related_domains: [], **)
            result = engine.create_domain(name: name, learning_rate: learning_rate, related_domains: related_domains)
            if result.is_a?(Hash) && result[:error]
              Legion::Logging.warn "[meta_learning] create_domain failed: #{result[:error]}"
              return result
            end

            Legion::Logging.debug "[meta_learning] domain created: #{result.name} id=#{result.id[0..7]}"
            result.to_h
          end

          def register_learning_strategy(name:, strategy_type:, **)
            result = engine.create_strategy(name: name, strategy_type: strategy_type)
            if result.is_a?(Hash) && result[:error]
              Legion::Logging.warn "[meta_learning] create_strategy failed: #{result[:error]}"
              return result
            end

            Legion::Logging.debug "[meta_learning] strategy registered: #{result.name} type=#{result.strategy_type}"
            result.to_h
          end

          def record_learning_episode(domain_id:, success:, strategy_id: nil, **)
            result = engine.record_episode(domain_id: domain_id, strategy_id: strategy_id, success: success)
            if result.is_a?(Hash) && result[:error]
              Legion::Logging.warn "[meta_learning] record_episode failed: #{result[:error]}"
              return result
            end

            Legion::Logging.debug "[meta_learning] episode recorded domain=#{result[:domain_name]} " \
                                  "success=#{success} proficiency=#{result[:proficiency].round(4)}"
            result
          end

          def recommend_learning_strategy(domain_id:, **)
            result = engine.recommend_strategy(domain_id: domain_id)
            Legion::Logging.debug "[meta_learning] strategy recommendation domain=#{domain_id[0..7]} " \
                                  "recommendation=#{result[:recommendation]}"
            result
          end

          def check_transfer_learning(source_domain_id:, target_domain_id:, **)
            result = engine.transfer_check(source_domain_id: source_domain_id, target_domain_id: target_domain_id)
            Legion::Logging.debug "[meta_learning] transfer check eligible=#{result[:eligible]}"
            result
          end

          def apply_transfer_bonus(source_domain_id:, target_domain_id:, **)
            result = engine.apply_transfer(source_domain_id: source_domain_id, target_domain_id: target_domain_id)
            Legion::Logging.info "[meta_learning] transfer applied=#{result[:applied]}"
            result
          end

          def learning_domain_ranking(limit: 10, **)
            ranking = engine.domain_ranking(limit: limit)
            Legion::Logging.debug "[meta_learning] domain ranking returned #{ranking.size} domains"
            { ranking: ranking, count: ranking.size }
          end

          def learning_strategy_ranking(limit: 10, **)
            ranking = engine.strategy_ranking(limit: limit)
            Legion::Logging.debug "[meta_learning] strategy ranking returned #{ranking.size} strategies"
            { ranking: ranking, count: ranking.size }
          end

          def learning_curve_report(domain_id:, **)
            result = engine.learning_curve(domain_id: domain_id)
            if result.is_a?(Hash) && result[:error]
              Legion::Logging.warn "[meta_learning] learning_curve failed: #{result[:error]}"
              return result
            end

            Legion::Logging.debug "[meta_learning] learning curve domain=#{result[:domain]} " \
                                  "episodes=#{result[:curve].size}"
            result
          end

          def update_meta_learning(**)
            adapt_result = engine.adapt_rates
            prune_result = engine.prune_stale_domains
            stats        = engine.to_h
            Legion::Logging.info "[meta_learning] update: adapted=#{adapt_result[:count]} " \
                                 "pruned=#{prune_result[:pruned]} domains=#{stats[:domain_count]}"
            { adapt: adapt_result, prune: prune_result, stats: stats }
          end

          def meta_learning_stats(**)
            stats = engine.to_h
            Legion::Logging.debug "[meta_learning] stats domains=#{stats[:domain_count]} " \
                                  "strategies=#{stats[:strategy_count]} efficiency=#{stats[:overall_efficiency]}"
            stats
          end

          private

          def engine
            @engine ||= Helpers::MetaLearningEngine.new
          end
        end
      end
    end
  end
end
