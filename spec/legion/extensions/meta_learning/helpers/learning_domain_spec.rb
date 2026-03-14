# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetaLearning::Helpers::LearningDomain do
  subject(:domain) { described_class.new(name: 'ruby') }

  describe '#initialize' do
    it 'sets a uuid id' do
      expect(domain.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets name' do
      expect(domain.name).to eq('ruby')
    end

    it 'starts with zero proficiency' do
      expect(domain.proficiency).to eq(0.0)
    end

    it 'uses default learning rate' do
      expect(domain.learning_rate).to eq(0.1)
    end

    it 'starts with zero successes and failures' do
      expect(domain.successes).to eq(0)
      expect(domain.failures).to eq(0)
    end

    it 'accepts custom learning rate' do
      d = described_class.new(name: 'go', learning_rate: 0.3)
      expect(d.learning_rate).to eq(0.3)
    end

    it 'accepts related_domains' do
      d = described_class.new(name: 'go', related_domains: ['ruby'])
      expect(d.related_domains).to include('ruby')
    end
  end

  describe '#record_success!' do
    it 'increments successes and episodes_count' do
      domain.record_success!
      expect(domain.successes).to eq(1)
      expect(domain.episodes_count).to eq(1)
    end

    it 'increases proficiency by learning_rate' do
      domain.record_success!
      expect(domain.proficiency).to be_within(0.0001).of(0.1)
    end

    it 'does not exceed proficiency of 1.0' do
      15.times { domain.record_success! }
      expect(domain.proficiency).to be <= 1.0
    end
  end

  describe '#record_failure!' do
    it 'increments failures and episodes_count' do
      domain.record_failure!
      expect(domain.failures).to eq(1)
      expect(domain.episodes_count).to eq(1)
    end

    it 'does not drop proficiency below 0.0' do
      domain.record_failure!
      expect(domain.proficiency).to be >= 0.0
    end

    it 'decreases proficiency when above zero' do
      5.times { domain.record_success! }
      proficiency_before = domain.proficiency
      domain.record_failure!
      expect(domain.proficiency).to be < proficiency_before
    end
  end

  describe '#efficiency' do
    it 'returns 0.0 with no episodes' do
      expect(domain.efficiency).to eq(0.0)
    end

    it 'returns 1.0 with all successes' do
      3.times { domain.record_success! }
      expect(domain.efficiency).to eq(1.0)
    end

    it 'returns 0.5 with equal successes and failures' do
      2.times { domain.record_success! }
      2.times { domain.record_failure! }
      expect(domain.efficiency).to eq(0.5)
    end
  end

  describe '#efficiency_label' do
    it 'returns :struggling for 0.0 efficiency' do
      expect(domain.efficiency_label).to eq(:struggling)
    end

    it 'returns :highly_efficient for 1.0 efficiency' do
      3.times { domain.record_success! }
      expect(domain.efficiency_label).to eq(:highly_efficient)
    end
  end

  describe '#proficiency_label' do
    it 'returns :beginner for new domain' do
      expect(domain.proficiency_label).to eq(:beginner)
    end

    it 'returns :expert when proficiency >= 0.8' do
      d = described_class.new(name: 'test', learning_rate: 0.9)
      d.record_success!
      expect(d.proficiency_label).to eq(:expert)
    end
  end

  describe '#adapt_rate!' do
    it 'increases learning rate with positive delta' do
      domain.adapt_rate!(delta: 0.05)
      expect(domain.learning_rate).to be_within(0.0001).of(0.15)
    end

    it 'decreases learning rate with negative delta' do
      domain.adapt_rate!(delta: -0.05)
      expect(domain.learning_rate).to be_within(0.0001).of(0.05)
    end

    it 'clamps rate to minimum 0.001' do
      domain.adapt_rate!(delta: -999.0)
      expect(domain.learning_rate).to eq(0.001)
    end

    it 'clamps rate to maximum 1.0' do
      domain.adapt_rate!(delta: 999.0)
      expect(domain.learning_rate).to eq(1.0)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = domain.to_h
      expect(h).to include(:id, :name, :proficiency, :learning_rate, :successes, :failures,
                           :efficiency, :proficiency_label, :efficiency_label, :related_domains)
    end
  end
end
