# frozen_string_literal: true

require 'legion/extensions/meta_learning/client'

RSpec.describe Legion::Extensions::MetaLearning::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:create_learning_domain)
    expect(client).to respond_to(:register_learning_strategy)
    expect(client).to respond_to(:record_learning_episode)
    expect(client).to respond_to(:recommend_learning_strategy)
    expect(client).to respond_to(:check_transfer_learning)
    expect(client).to respond_to(:apply_transfer_bonus)
    expect(client).to respond_to(:learning_domain_ranking)
    expect(client).to respond_to(:learning_strategy_ranking)
    expect(client).to respond_to(:learning_curve_report)
    expect(client).to respond_to(:update_meta_learning)
    expect(client).to respond_to(:meta_learning_stats)
  end

  it 'maintains isolated state per instance' do
    c1 = described_class.new
    c2 = described_class.new
    c1.create_learning_domain(name: 'ruby')
    expect(c2.meta_learning_stats[:domain_count]).to eq(0)
  end
end
