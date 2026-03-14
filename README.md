# lex-meta-learning

Learning-to-learn management for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-meta-learning` tracks how an agent learns across knowledge domains and refines its learning strategies over time. It registers strategy types (rehearsal, spaced repetition, retrieval practice, etc.), records learning episodes with outcomes, recommends the most effective strategy per domain, and detects when proficiency in one domain can accelerate learning in another (transfer learning).

Key capabilities:

- **Domain proficiency tracking**: 0..1 proficiency score per domain with episode history
- **Strategy effectiveness**: success rate tracking per strategy per domain
- **Transfer learning**: detects when source domain proficiency >= 0.6 can boost a target domain
- **Strategy recommendation**: returns the highest-success-rate strategy for a given domain
- **Learning curve**: episode-by-episode proficiency progression data

## Installation

Add to your Gemfile:

```ruby
gem 'lex-meta-learning'
```

Or install directly:

```
gem install lex-meta-learning
```

## Usage

```ruby
require 'legion/extensions/meta_learning'

client = Legion::Extensions::MetaLearning::Client.new

# Register domains and strategies
client.create_learning_domain(name: :ruby_patterns)
client.register_learning_strategy(name: :spaced_rep, type: :spaced_repetition)
client.register_learning_strategy(name: :retrieval, type: :retrieval_practice)

# Record a learning episode
client.record_learning_episode(
  domain: :ruby_patterns, strategy: :spaced_rep,
  success: true, gain: 0.08
)

# Get strategy recommendation
rec = client.recommend_learning_strategy(domain: :ruby_patterns)
# => { strategy: :spaced_rep, success_rate: 0.8, efficiency: :efficient }

# Check for transfer learning opportunity
client.check_transfer_learning(source_domain: :ruby_patterns, target_domain: :rails_patterns)
# => { transfer_possible: true, source_proficiency: 0.7 }

# Apply the transfer bonus
client.apply_transfer_bonus(source: :ruby_patterns, target: :rails_patterns)

# View learning curve
client.learning_curve_report(domain: :ruby_patterns)

# Stats
client.meta_learning_stats
```

## Runner Methods

| Method | Description |
|---|---|
| `create_learning_domain` | Register a new knowledge domain |
| `register_learning_strategy` | Register a learning strategy |
| `record_learning_episode` | Record an episode with outcome and proficiency gain |
| `recommend_learning_strategy` | Best strategy for a domain based on past success |
| `check_transfer_learning` | Check if proficiency transfers from source to target |
| `apply_transfer_bonus` | Apply transfer bonus to target domain proficiency |
| `learning_domain_ranking` | Top N domains by proficiency |
| `learning_strategy_ranking` | Top N strategies by success rate |
| `learning_curve_report` | Proficiency progression data for a domain |
| `update_meta_learning` | Extract learning signals from tick; adapt rates |
| `meta_learning_stats` | Domain count, strategy count, episode count, top domain |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
