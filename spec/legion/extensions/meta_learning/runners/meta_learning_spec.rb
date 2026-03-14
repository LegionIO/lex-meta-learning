# frozen_string_literal: true

require 'legion/extensions/meta_learning/client'

RSpec.describe Legion::Extensions::MetaLearning::Runners::MetaLearning do
  let(:client) { Legion::Extensions::MetaLearning::Client.new }

  let(:domain_result) { client.create_learning_domain(name: 'ruby') }
  let(:domain_id)     { domain_result[:id] }
  let(:strategy_result) { client.register_learning_strategy(name: 'flash_cards', strategy_type: :repetition) }
  let(:strategy_id) { strategy_result[:id] }

  describe '#create_learning_domain' do
    it 'returns a hash with id and name' do
      result = client.create_learning_domain(name: 'python')
      expect(result[:id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:name]).to eq('python')
    end

    it 'applies custom learning rate' do
      result = client.create_learning_domain(name: 'go', learning_rate: 0.2)
      expect(result[:learning_rate]).to be_within(0.0001).of(0.2)
    end

    it 'accepts related_domains array' do
      result = client.create_learning_domain(name: 'typescript', related_domains: ['javascript'])
      expect(result[:related_domains]).to include('javascript')
    end

    it 'returns error hash on limit reached' do
      stub_const('Legion::Extensions::MetaLearning::Helpers::Constants::MAX_DOMAINS', 0)
      result = client.create_learning_domain(name: 'test')
      expect(result[:error]).to eq(:limit_reached)
    end
  end

  describe '#register_learning_strategy' do
    it 'returns a hash with id and name' do
      result = client.register_learning_strategy(name: 'analogy', strategy_type: :analogy)
      expect(result[:id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:name]).to eq('analogy')
    end

    it 'returns error for invalid strategy_type' do
      result = client.register_learning_strategy(name: 'bad', strategy_type: :invalid)
      expect(result[:error]).to eq(:invalid_strategy_type)
    end
  end

  describe '#record_learning_episode' do
    it 'records a success and returns episode hash' do
      result = client.record_learning_episode(domain_id: domain_id, success: true)
      expect(result[:success]).to be true
      expect(result[:domain_name]).to eq('ruby')
    end

    it 'records a failure' do
      result = client.record_learning_episode(domain_id: domain_id, success: false)
      expect(result[:success]).to be false
    end

    it 'returns error for unknown domain' do
      result = client.record_learning_episode(domain_id: 'bad', success: true)
      expect(result[:error]).to eq(:domain_not_found)
    end

    it 'accepts strategy_id' do
      sid = strategy_id
      result = client.record_learning_episode(domain_id: domain_id, strategy_id: sid, success: true)
      expect(result[:strategy_id]).to eq(sid)
    end
  end

  describe '#recommend_learning_strategy' do
    it 'returns no_data when no strategy history' do
      result = client.recommend_learning_strategy(domain_id: domain_id)
      expect(result[:reason]).to eq(:no_data)
    end

    it 'recommends best strategy after episodes' do
      sid = strategy_id
      did = domain_id
      3.times { client.record_learning_episode(domain_id: did, strategy_id: sid, success: true) }
      result = client.recommend_learning_strategy(domain_id: did)
      expect(result[:recommendation]).to eq('flash_cards')
    end

    it 'returns error for unknown domain' do
      result = client.recommend_learning_strategy(domain_id: 'bad')
      expect(result[:error]).to eq(:domain_not_found)
    end
  end

  describe '#check_transfer_learning' do
    it 'returns not eligible when source proficiency is low' do
      d1 = client.create_learning_domain(name: 'source')
      d2 = client.create_learning_domain(name: 'target', related_domains: ['source'])
      result = client.check_transfer_learning(source_domain_id: d1[:id], target_domain_id: d2[:id])
      expect(result[:eligible]).to be false
    end

    it 'returns error for unknown domains' do
      result = client.check_transfer_learning(source_domain_id: 'bad', target_domain_id: 'also-bad')
      expect(result[:error]).to eq(:domain_not_found)
    end
  end

  describe '#apply_transfer_bonus' do
    it 'returns not applied when not eligible' do
      d1 = client.create_learning_domain(name: 'src')
      d2 = client.create_learning_domain(name: 'tgt', related_domains: ['src'])
      result = client.apply_transfer_bonus(source_domain_id: d1[:id], target_domain_id: d2[:id])
      expect(result[:applied]).to be false
    end

    it 'returns error for unknown domains' do
      result = client.apply_transfer_bonus(source_domain_id: 'x', target_domain_id: 'y')
      expect(result[:error]).to eq(:domain_not_found)
    end
  end

  describe '#learning_domain_ranking' do
    it 'returns ranking and count' do
      client.create_learning_domain(name: 'a')
      client.create_learning_domain(name: 'b')
      result = client.learning_domain_ranking
      expect(result[:ranking]).to be_an(Array)
      expect(result[:count]).to eq(2)
    end

    it 'respects limit parameter' do
      5.times { |i| client.create_learning_domain(name: "d#{i}") }
      result = client.learning_domain_ranking(limit: 2)
      expect(result[:ranking].size).to eq(2)
    end
  end

  describe '#learning_strategy_ranking' do
    it 'returns ranking and count' do
      client.register_learning_strategy(name: 's1', strategy_type: :repetition)
      result = client.learning_strategy_ranking
      expect(result[:ranking]).to be_an(Array)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#learning_curve_report' do
    it 'returns error for unknown domain' do
      result = client.learning_curve_report(domain_id: 'bad')
      expect(result[:error]).to eq(:domain_not_found)
    end

    it 'returns curve data for valid domain' do
      did = domain_id
      2.times { client.record_learning_episode(domain_id: did, success: true) }
      result = client.learning_curve_report(domain_id: did)
      expect(result[:domain]).to eq('ruby')
      expect(result[:curve].size).to eq(2)
    end
  end

  describe '#update_meta_learning' do
    it 'returns adapt, prune, and stats' do
      result = client.update_meta_learning
      expect(result).to include(:adapt, :prune, :stats)
    end

    it 'boosts rate for efficient domains' do
      did = domain_id
      5.times { client.record_learning_episode(domain_id: did, success: true) }
      result = client.update_meta_learning
      expect(result[:adapt][:count]).to eq(1)
      expect(result[:adapt][:adapted].first[:direction]).to eq(:boost)
    end
  end

  describe '#meta_learning_stats' do
    it 'returns engine stats hash' do
      domain_id
      result = client.meta_learning_stats
      expect(result).to include(:domain_count, :strategy_count, :episode_count, :overall_efficiency)
      expect(result[:domain_count]).to eq(1)
    end
  end
end
