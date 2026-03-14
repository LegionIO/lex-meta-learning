# frozen_string_literal: true

RSpec.describe Legion::Extensions::MetaLearning::Helpers::Constants do
  it 'defines MAX_DOMAINS as 100' do
    expect(described_module::MAX_DOMAINS).to eq(100)
  end

  it 'defines MAX_STRATEGIES as 50' do
    expect(described_module::MAX_STRATEGIES).to eq(50)
  end

  it 'defines MAX_EPISODES as 1000' do
    expect(described_module::MAX_EPISODES).to eq(1000)
  end

  it 'defines DEFAULT_LEARNING_RATE as 0.1' do
    expect(described_module::DEFAULT_LEARNING_RATE).to eq(0.1)
  end

  it 'defines STRATEGY_TYPES as an array of symbols' do
    expect(described_module::STRATEGY_TYPES).to be_an(Array)
    expect(described_module::STRATEGY_TYPES).to all(be_a(Symbol))
    expect(described_module::STRATEGY_TYPES).to include(:repetition, :elaboration, :retrieval_practice)
  end

  it 'defines PROFICIENCY_LABELS covering full 0..1 range' do
    labels = [0.0, 0.1, 0.25, 0.45, 0.65, 0.85].map do |v|
      described_module::PROFICIENCY_LABELS.find { |range, _| range.cover?(v) }&.last
    end
    expect(labels).to all(be_a(Symbol))
  end

  it 'defines EFFICIENCY_LABELS covering full 0..1 range' do
    labels = [0.0, 0.1, 0.25, 0.45, 0.65, 0.85].map do |v|
      described_module::EFFICIENCY_LABELS.find { |range, _| range.cover?(v) }&.last
    end
    expect(labels).to all(be_a(Symbol))
  end

  def described_module
    Legion::Extensions::MetaLearning::Helpers::Constants
  end
end
