# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetaLearning::Helpers::Strategy do
  subject(:strategy) { described_class.new(name: 'flash_cards', strategy_type: :repetition) }

  describe '#initialize' do
    it 'sets a uuid id' do
      expect(strategy.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets name and strategy_type' do
      expect(strategy.name).to eq('flash_cards')
      expect(strategy.strategy_type).to eq(:repetition)
    end

    it 'starts with zero usage_count and success_count' do
      expect(strategy.usage_count).to eq(0)
      expect(strategy.success_count).to eq(0)
    end
  end

  describe '#use!' do
    it 'increments usage_count' do
      strategy.use!(success: true)
      expect(strategy.usage_count).to eq(1)
    end

    it 'increments success_count on success' do
      strategy.use!(success: true)
      expect(strategy.success_count).to eq(1)
    end

    it 'does not increment success_count on failure' do
      strategy.use!(success: false)
      expect(strategy.success_count).to eq(0)
    end

    it 'tracks domain names uniquely' do
      strategy.use!(success: true, domain_name: 'ruby')
      strategy.use!(success: true, domain_name: 'ruby')
      strategy.use!(success: true, domain_name: 'python')
      expect(strategy.domains_used.uniq.size).to eq(2)
    end
  end

  describe '#success_rate' do
    it 'returns 0.0 with no uses' do
      expect(strategy.success_rate).to eq(0.0)
    end

    it 'returns 1.0 with all successes' do
      3.times { strategy.use!(success: true) }
      expect(strategy.success_rate).to eq(1.0)
    end

    it 'returns 0.5 with equal success and failure' do
      strategy.use!(success: true)
      strategy.use!(success: false)
      expect(strategy.success_rate).to eq(0.5)
    end
  end

  describe '#versatility' do
    it 'returns 0 for unused strategy' do
      expect(strategy.versatility).to eq(0)
    end

    it 'returns count of unique domains used' do
      strategy.use!(success: true, domain_name: 'ruby')
      strategy.use!(success: true, domain_name: 'python')
      expect(strategy.versatility).to eq(2)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = strategy.to_h
      expect(h).to include(:id, :name, :strategy_type, :usage_count, :success_count,
                           :success_rate, :versatility, :domains_used, :created_at)
    end
  end
end
