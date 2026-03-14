# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetaLearning::Helpers::MetaLearningEngine do
  subject(:engine) { described_class.new }

  let(:ruby_domain) { engine.create_domain(name: 'ruby') }
  let(:python_domain) { engine.create_domain(name: 'python', related_domains: ['ruby']) }
  let(:flash_strategy) do
    engine.create_strategy(name: 'flash_cards', strategy_type: :repetition)
  end

  describe '#create_domain' do
    it 'returns a LearningDomain' do
      expect(ruby_domain).to be_a(Legion::Extensions::MetaLearning::Helpers::LearningDomain)
    end

    it 'stores the domain by id' do
      d = ruby_domain
      expect(engine.domains[d.id]).to eq(d)
    end

    it 'returns error hash when limit reached' do
      stub_const('Legion::Extensions::MetaLearning::Helpers::Constants::MAX_DOMAINS', 0)
      result = engine.create_domain(name: 'test')
      expect(result[:error]).to eq(:limit_reached)
    end
  end

  describe '#create_strategy' do
    it 'returns a Strategy' do
      expect(flash_strategy).to be_a(Legion::Extensions::MetaLearning::Helpers::Strategy)
    end

    it 'returns error for invalid strategy_type' do
      result = engine.create_strategy(name: 'bad', strategy_type: :nonexistent)
      expect(result[:error]).to eq(:invalid_strategy_type)
    end

    it 'returns error when limit reached' do
      stub_const('Legion::Extensions::MetaLearning::Helpers::Constants::MAX_STRATEGIES', 0)
      result = engine.create_strategy(name: 'test', strategy_type: :repetition)
      expect(result[:error]).to eq(:limit_reached)
    end
  end

  describe '#record_episode' do
    context 'with valid domain' do
      it 'records a successful episode' do
        d = ruby_domain
        result = engine.record_episode(domain_id: d.id, success: true)
        expect(result[:success]).to be true
        expect(result[:domain_name]).to eq('ruby')
      end

      it 'records a failure episode' do
        d = ruby_domain
        result = engine.record_episode(domain_id: d.id, success: false)
        expect(result[:success]).to be false
      end

      it 'updates domain proficiency on success' do
        d = ruby_domain
        engine.record_episode(domain_id: d.id, success: true)
        expect(d.proficiency).to be > 0.0
      end

      it 'appends to episodes array' do
        d = ruby_domain
        engine.record_episode(domain_id: d.id, success: true)
        expect(engine.episodes.size).to eq(1)
      end

      it 'records strategy usage when strategy_id provided' do
        d = ruby_domain
        s = flash_strategy
        engine.record_episode(domain_id: d.id, strategy_id: s.id, success: true)
        expect(s.usage_count).to eq(1)
      end

      it 'sets preferred_strategy after successful use' do
        d = ruby_domain
        s = flash_strategy
        engine.record_episode(domain_id: d.id, strategy_id: s.id, success: true)
        expect(d.preferred_strategy).to eq('flash_cards')
      end
    end

    context 'with invalid domain' do
      it 'returns error hash' do
        result = engine.record_episode(domain_id: 'bad-id', success: true)
        expect(result[:error]).to eq(:domain_not_found)
      end
    end
  end

  describe '#recommend_strategy' do
    it 'returns error for unknown domain' do
      result = engine.recommend_strategy(domain_id: 'bad')
      expect(result[:error]).to eq(:domain_not_found)
    end

    it 'returns no_data when no strategies used' do
      d = ruby_domain
      result = engine.recommend_strategy(domain_id: d.id)
      expect(result[:reason]).to eq(:no_data)
    end

    it 'recommends the best performing strategy' do
      d = ruby_domain
      s1 = engine.create_strategy(name: 'cards', strategy_type: :repetition)
      s2 = engine.create_strategy(name: 'elaboration', strategy_type: :elaboration)
      3.times { engine.record_episode(domain_id: d.id, strategy_id: s1.id, success: true) }
      engine.record_episode(domain_id: d.id, strategy_id: s2.id, success: false)
      result = engine.recommend_strategy(domain_id: d.id)
      expect(result[:recommendation]).to eq('cards')
    end

    it 'recommends via related domains when no direct data' do
      d_ruby   = ruby_domain
      d_python = python_domain
      s        = flash_strategy
      3.times { engine.record_episode(domain_id: d_ruby.id, strategy_id: s.id, success: true) }
      result = engine.recommend_strategy(domain_id: d_python.id)
      expect(result[:recommendation]).to eq('flash_cards')
    end
  end

  describe '#transfer_check' do
    it 'returns error if domain not found' do
      result = engine.transfer_check(source_domain_id: 'bad', target_domain_id: 'also-bad')
      expect(result[:error]).to eq(:domain_not_found)
    end

    it 'returns not eligible when source proficiency is low' do
      d_ruby   = ruby_domain
      d_python = python_domain
      result = engine.transfer_check(source_domain_id: d_ruby.id, target_domain_id: d_python.id)
      expect(result[:eligible]).to be false
    end

    it 'returns eligible when source is proficient and domains are related' do
      d_ruby   = ruby_domain
      d_python = python_domain
      d = described_class.new
      d_ruby_high = d.create_domain(name: 'ruby')
      d_python_rel = d.create_domain(name: 'python', related_domains: ['ruby'])
      8.times { d.record_episode(domain_id: d_ruby_high.id, success: true) }
      result = d.transfer_check(source_domain_id: d_ruby_high.id, target_domain_id: d_python_rel.id)
      expect(result[:eligible]).to be true
      expect(d_ruby).not_to be_nil
      expect(d_python).not_to be_nil
    end
  end

  describe '#apply_transfer' do
    it 'returns error if domain not found' do
      result = engine.apply_transfer(source_domain_id: 'bad', target_domain_id: 'also-bad')
      expect(result[:error]).to eq(:domain_not_found)
    end

    it 'returns not applied when not eligible' do
      d_ruby   = ruby_domain
      d_python = python_domain
      result = engine.apply_transfer(source_domain_id: d_ruby.id, target_domain_id: d_python.id)
      expect(result[:applied]).to be false
    end

    it 'applies transfer bonus to target learning rate' do
      eng         = described_class.new
      src         = eng.create_domain(name: 'ruby')
      tgt         = eng.create_domain(name: 'python', related_domains: ['ruby'])
      8.times { eng.record_episode(domain_id: src.id, success: true) }
      original_rate = tgt.learning_rate
      result = eng.apply_transfer(source_domain_id: src.id, target_domain_id: tgt.id)
      expect(result[:applied]).to be true
      expect(tgt.learning_rate).to be > original_rate
    end
  end

  describe '#domain_ranking' do
    it 'returns domains sorted by proficiency descending' do
      d1 = engine.create_domain(name: 'ruby')
      d2 = engine.create_domain(name: 'python')
      3.times { engine.record_episode(domain_id: d1.id, success: true) }
      engine.record_episode(domain_id: d2.id, success: true)
      ranking = engine.domain_ranking
      expect(ranking.first[:name]).to eq('ruby')
    end

    it 'respects the limit parameter' do
      5.times { |i| engine.create_domain(name: "domain_#{i}") }
      expect(engine.domain_ranking(limit: 3).size).to eq(3)
    end
  end

  describe '#strategy_ranking' do
    it 'returns strategies sorted by success_rate descending' do
      s1 = engine.create_strategy(name: 'good', strategy_type: :repetition)
      s2 = engine.create_strategy(name: 'bad', strategy_type: :elaboration)
      d  = ruby_domain
      3.times { engine.record_episode(domain_id: d.id, strategy_id: s1.id, success: true) }
      engine.record_episode(domain_id: d.id, strategy_id: s2.id, success: false)
      ranking = engine.strategy_ranking
      expect(ranking.first[:name]).to eq('good')
    end
  end

  describe '#overall_efficiency' do
    it 'returns 0.0 with no domains' do
      expect(engine.overall_efficiency).to eq(0.0)
    end

    it 'returns average efficiency across domains' do
      d1 = engine.create_domain(name: 'ruby')
      d2 = engine.create_domain(name: 'python')
      2.times { engine.record_episode(domain_id: d1.id, success: true) }
      2.times { engine.record_episode(domain_id: d2.id, success: false) }
      expect(engine.overall_efficiency).to eq(0.5)
    end
  end

  describe '#learning_curve' do
    it 'returns error for unknown domain' do
      result = engine.learning_curve(domain_id: 'bad')
      expect(result[:error]).to eq(:domain_not_found)
    end

    it 'returns episodes for domain in order' do
      d = ruby_domain
      3.times { engine.record_episode(domain_id: d.id, success: true) }
      result = engine.learning_curve(domain_id: d.id)
      expect(result[:curve].size).to eq(3)
      expect(result[:domain]).to eq('ruby')
    end

    it 'includes proficiency snapshots' do
      d = ruby_domain
      engine.record_episode(domain_id: d.id, success: true)
      result = engine.learning_curve(domain_id: d.id)
      expect(result[:curve].first).to have_key(:proficiency)
    end
  end

  describe '#adapt_rates' do
    it 'boosts rate for highly efficient domain' do
      d = engine.create_domain(name: 'ruby')
      5.times { engine.record_episode(domain_id: d.id, success: true) }
      original_rate = d.learning_rate
      engine.adapt_rates
      expect(d.learning_rate).to be > original_rate
    end

    it 'decays rate for struggling domain' do
      d = engine.create_domain(name: 'ruby')
      5.times { engine.record_episode(domain_id: d.id, success: false) }
      original_rate = d.learning_rate
      engine.adapt_rates
      expect(d.learning_rate).to be < original_rate
    end

    it 'returns count of adapted domains' do
      d = engine.create_domain(name: 'ruby')
      5.times { engine.record_episode(domain_id: d.id, success: true) }
      result = engine.adapt_rates
      expect(result[:count]).to eq(1)
    end

    it 'skips domains with no episodes' do
      engine.create_domain(name: 'virgin')
      result = engine.adapt_rates
      expect(result[:count]).to eq(0)
    end
  end

  describe '#prune_stale_domains' do
    it 'removes domains with fewer than min_episodes' do
      engine.create_domain(name: 'stale')
      result = engine.prune_stale_domains(min_episodes: 1)
      expect(result[:pruned]).to eq(1)
      expect(result[:remaining]).to eq(0)
    end

    it 'keeps domains that meet the threshold' do
      d = engine.create_domain(name: 'active')
      engine.record_episode(domain_id: d.id, success: true)
      result = engine.prune_stale_domains(min_episodes: 1)
      expect(result[:pruned]).to eq(0)
      expect(result[:remaining]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns engine stats hash' do
      ruby_domain
      h = engine.to_h
      expect(h).to include(:domain_count, :strategy_count, :episode_count, :overall_efficiency)
      expect(h[:domain_count]).to eq(1)
    end
  end

  describe 'episode cap' do
    it 'does not exceed MAX_EPISODES' do
      stub_const('Legion::Extensions::MetaLearning::Helpers::Constants::MAX_EPISODES', 3)
      d = engine.create_domain(name: 'ruby')
      5.times { engine.record_episode(domain_id: d.id, success: true) }
      expect(engine.episodes.size).to eq(3)
    end
  end
end
