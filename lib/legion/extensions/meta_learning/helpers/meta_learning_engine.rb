# frozen_string_literal: true

module Legion
  module Extensions
    module MetaLearning
      module Helpers
        class MetaLearningEngine
          include Constants

          attr_reader :domains, :strategies, :episodes

          def initialize
            @domains    = {}
            @strategies = {}
            @episodes   = []
          end

          def create_domain(name:, learning_rate: DEFAULT_LEARNING_RATE, related_domains: [])
            return { error: :limit_reached } if @domains.size >= MAX_DOMAINS

            domain = LearningDomain.new(name: name, learning_rate: learning_rate, related_domains: related_domains)
            @domains[domain.id] = domain
            domain
          end

          def create_strategy(name:, strategy_type:)
            return { error: :limit_reached } if @strategies.size >= MAX_STRATEGIES
            return { error: :invalid_strategy_type } unless STRATEGY_TYPES.include?(strategy_type)

            strategy = Strategy.new(name: name, strategy_type: strategy_type)
            @strategies[strategy.id] = strategy
            strategy
          end

          def record_episode(domain_id:, success:, strategy_id: nil)
            domain = @domains[domain_id]
            return { error: :domain_not_found } unless domain

            success ? domain.record_success! : domain.record_failure!

            strategy = @strategies[strategy_id] if strategy_id
            strategy&.use!(success: success, domain_name: domain.name)

            if strategy && success
              current_preferred_rate = preferred_strategy_rate_for(domain)
              domain.preferred_strategy = strategy.name if strategy.success_rate > current_preferred_rate
            end

            episode = build_episode(domain, strategy_id, success)
            @episodes << episode
            @episodes.shift while @episodes.size > MAX_EPISODES

            check_transfer_opportunities(domain)

            episode
          end

          def recommend_strategy(domain_id:)
            domain = @domains[domain_id]
            return { error: :domain_not_found } unless domain

            candidate = best_strategy_for_domain(domain)
            return { recommendation: nil, reason: :no_data } if candidate.nil?

            { recommendation: candidate.name, strategy_id: candidate.id, success_rate: candidate.success_rate }
          end

          def transfer_check(source_domain_id:, target_domain_id:)
            source = @domains[source_domain_id]
            target = @domains[target_domain_id]
            return { error: :domain_not_found } unless source && target

            eligible = source.proficiency >= 0.6 && target.related_domains.include?(source.name)
            { eligible: eligible, source_proficiency: source.proficiency, target_domain: target.name }
          end

          def apply_transfer(source_domain_id:, target_domain_id:)
            source = @domains[source_domain_id]
            target = @domains[target_domain_id]
            return { error: :domain_not_found } unless source && target

            check = transfer_check(source_domain_id: source_domain_id, target_domain_id: target_domain_id)
            return { applied: false, reason: :not_eligible } unless check[:eligible]

            target.adapt_rate!(delta: TRANSFER_BONUS)
            { applied: true, target_domain: target.name, new_learning_rate: target.learning_rate }
          end

          def domain_ranking(limit: 10)
            @domains.values
                    .sort_by { |d| -d.proficiency }
                    .first(limit)
                    .map(&:to_h)
          end

          def strategy_ranking(limit: 10)
            @strategies.values
                       .sort_by { |s| -s.success_rate }
                       .first(limit)
                       .map(&:to_h)
          end

          def overall_efficiency
            return 0.0 if @domains.empty?

            total = @domains.values.sum(&:efficiency)
            (total / @domains.size).round(10)
          end

          def learning_curve(domain_id:)
            domain = @domains[domain_id]
            return { error: :domain_not_found } unless domain

            domain_episodes = @episodes.select { |e| e[:domain_id] == domain_id }
            { domain: domain.name, curve: domain_episodes }
          end

          def adapt_rates
            adapted = []
            @domains.each_value do |domain|
              next if domain.episodes_count.zero?

              if domain.efficiency >= 0.8
                domain.adapt_rate!(delta: RATE_BOOST)
                adapted << { domain: domain.name, direction: :boost, new_rate: domain.learning_rate }
              elsif domain.efficiency < 0.2
                domain.adapt_rate!(delta: -RATE_DECAY)
                adapted << { domain: domain.name, direction: :decay, new_rate: domain.learning_rate }
              end
            end
            { adapted: adapted, count: adapted.size }
          end

          def prune_stale_domains(min_episodes: 1)
            before = @domains.size
            @domains.reject! { |_, d| d.episodes_count < min_episodes }
            pruned = before - @domains.size
            { pruned: pruned, remaining: @domains.size }
          end

          def to_h
            {
              domain_count:       @domains.size,
              strategy_count:     @strategies.size,
              episode_count:      @episodes.size,
              overall_efficiency: overall_efficiency,
              top_domain:         @domains.values.max_by(&:proficiency)&.name,
              top_strategy:       @strategies.values.max_by(&:success_rate)&.name
            }
          end

          private

          def build_episode(domain, strategy_id, success)
            {
              id:          SecureRandom.uuid,
              domain_id:   domain.id,
              domain_name: domain.name,
              strategy_id: strategy_id,
              success:     success,
              proficiency: domain.proficiency,
              recorded_at: Time.now.utc
            }
          end

          def preferred_strategy_rate_for(domain)
            return 0.0 unless domain.preferred_strategy

            strategy = @strategies.values.find { |s| s.name == domain.preferred_strategy }
            strategy&.success_rate || 0.0
          end

          def best_strategy_for_domain(domain)
            direct = strategies_used_in_domain(domain.name)
            return direct.max_by(&:success_rate) if direct.any?

            related_strategies = domain.related_domains.flat_map { |rname| strategies_used_in_domain(rname) }.uniq
            related_strategies.max_by(&:success_rate)
          end

          def strategies_used_in_domain(domain_name)
            @strategies.values.select { |s| s.domains_used.include?(domain_name) }
          end

          def check_transfer_opportunities(domain)
            @domains.each_value do |target|
              next if target.id == domain.id
              next unless target.related_domains.include?(domain.name)

              check = transfer_check(source_domain_id: domain.id, target_domain_id: target.id)
              apply_transfer(source_domain_id: domain.id, target_domain_id: target.id) if check[:eligible]
            end
          end
        end
      end
    end
  end
end
