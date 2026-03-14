# lex-meta-learning

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-meta-learning`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::MetaLearning`

## Purpose

Learning-to-learn management for LegionIO agents. Tracks how the agent learns across knowledge domains, registers strategy types (rehearsal, elaboration, interleaving, etc.), records learning episodes with outcomes, recommends optimal strategies per domain, detects cross-domain transfer opportunities, and provides learning curve analysis. Adapts strategy recommendations over time based on historical success rates.

## Gem Info

- **Require path**: `legion/extensions/meta_learning`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/meta_learning/
  version.rb
  helpers/
    constants.rb              # Limits, defaults, labels, strategy types
    learning_domain.rb        # LearningDomain value object
    strategy.rb               # Strategy value object with outcome tracking
    meta_learning_engine.rb   # In-memory domain + strategy + episode store
  runners/
    meta_learning.rb          # Runner module

spec/
  legion/extensions/meta_learning/
    helpers/
      constants_spec.rb
      learning_domain_spec.rb
      strategy_spec.rb
      meta_learning_engine_spec.rb
    runners/meta_learning_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MAX_DOMAINS       = 100
MAX_STRATEGIES    = 50
MAX_EPISODES      = 1000
DEFAULT_LEARNING_RATE = 0.1
TRANSFER_BONUS    = 0.05   # proficiency boost when transfer is detected

PROFICIENCY_LABELS = {
  (0.8..)     => :expert,
  (0.6...0.8) => :proficient,
  (0.4...0.6) => :developing,
  (0.2...0.4) => :novice,
  (..0.2)     => :beginner
}

EFFICIENCY_LABELS = {
  (0.8..)     => :highly_efficient,
  (0.6...0.8) => :efficient,
  (0.4...0.6) => :moderate,
  (0.2...0.4) => :inefficient,
  (..0.2)     => :very_inefficient
}

STRATEGY_TYPES = %i[
  rehearsal elaboration interleaving spaced_repetition
  retrieval_practice elaborative_interrogation
  self_explanation analogy_mapping dual_coding chunking
]
```

## Helpers

### `Helpers::LearningDomain` (class)

Tracks learning progress in a single knowledge domain.

| Attribute | Type | Description |
|---|---|---|
| `id` | String (UUID) | unique identifier |
| `name` | Symbol | domain name |
| `proficiency` | Float (0..1) | current knowledge level |
| `episodes` | Integer | total learning episodes recorded |
| `learning_rate` | Float | current rate for this domain |
| `last_active` | Time | last episode timestamp |

Key methods:
- `proficiency_label` — :beginner / :novice / :developing / :proficient / :expert
- `advance(amount)` — proficiency += amount (capped at 1.0)
- `stale?(threshold)` — true if last_active older than threshold

### `Helpers::Strategy` (class)

A named learning strategy with outcome tracking.

| Attribute | Type | Description |
|---|---|---|
| `id` | String (UUID) | unique identifier |
| `name` | Symbol | strategy name |
| `strategy_type` | Symbol | from STRATEGY_TYPES |
| `uses` | Integer | application count |
| `successes` | Integer | successful episodes using this strategy |
| `domains` | Array<Symbol> | domains where this strategy has been applied |

Key methods:
- `record_outcome(success:)` — increments uses; increments successes if success
- `success_rate` — successes / uses (nil if uses == 0)
- `efficiency_label` — from EFFICIENCY_LABELS based on success_rate

### `Helpers::MetaLearningEngine` (class)

Central store for domains, strategies, and learning episodes.

| Method | Description |
|---|---|
| `create_domain(name:)` | creates domain if not already present; enforces MAX_DOMAINS |
| `create_strategy(name:, type:)` | registers strategy; enforces MAX_STRATEGIES |
| `record_episode(domain:, strategy:, success:, gain:)` | records episode; updates domain proficiency by `gain`; records strategy outcome |
| `recommend_strategy(domain:)` | returns highest-success-rate strategy for the domain |
| `transfer_check(source_domain:, target_domain:)` | checks if source proficiency >= 0.6 and domains share strategy types |
| `apply_transfer(source:, target:)` | applies TRANSFER_BONUS to target domain proficiency |
| `domain_ranking(limit:)` | top N domains by proficiency |
| `strategy_ranking(limit:)` | top N strategies by success_rate |
| `learning_curve(domain:)` | episode-by-episode proficiency progression |
| `adapt_rates` | adjusts per-domain learning rates based on recent episode gains |
| `prune_stale_domains(threshold:)` | removes domains with no activity in `threshold` seconds |

## Runners

Module: `Legion::Extensions::MetaLearning::Runners::MetaLearning`

Private state: `@engine` (memoized `MetaLearningEngine` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `create_learning_domain` | `name:` | Register a new learning domain |
| `register_learning_strategy` | `name:, type:` | Register a learning strategy |
| `record_learning_episode` | `domain:, strategy:, success:, gain: 0.05` | Record an episode |
| `recommend_learning_strategy` | `domain:` | Best strategy for a domain |
| `check_transfer_learning` | `source_domain:, target_domain:` | Check for transfer opportunity |
| `apply_transfer_bonus` | `source:, target:` | Apply transfer bonus to target |
| `learning_domain_ranking` | `limit: 10` | Top N domains by proficiency |
| `learning_strategy_ranking` | `limit: 10` | Top N strategies by success rate |
| `learning_curve_report` | `domain:` | Proficiency progression data |
| `update_meta_learning` | `tick_results: {}` | Extract learning signals from tick; adapt rates |
| `meta_learning_stats` | (none) | Domain count, strategy count, episode count, top domain |

## Integration Points

- **lex-learning-rate**: meta-learning tracks proficiency progression per domain; learning-rate adjusts the step size. Both inform how quickly the agent absorbs information in a domain.
- **lex-memory**: learning episodes correspond to memory reinforcement; high-proficiency domains should yield higher-confidence memory traces.
- **lex-prediction**: prediction accuracy per domain feeds `record_learning_episode` — correct predictions indicate learning gains.
- **lex-metacognition**: `MetaLearning` is listed under `:cognition` capability category.

## Development Notes

- Proficiency is monotonically increasing (capped at 1.0) — there is no proficiency decay in the current implementation. Once mastered, a domain stays mastered.
- `recommend_strategy` returns the highest-success-rate strategy applied to the target domain. If no strategy has been applied to that domain yet, it returns the globally highest-success-rate strategy.
- `transfer_check` is a heuristic: source domain proficiency >= 0.6 AND at least one overlapping strategy type. There is no semantic similarity check between domains.
- `MAX_EPISODES` is total across all domains. When reached, oldest episodes are pruned (FIFO). Episode count is distinct from domain episode counters (which are not decremented on prune).
- `adapt_rates` uses recent gain averages to adjust per-domain learning_rate, not the global DEFAULT_LEARNING_RATE.
- No actor defined; `update_meta_learning` is driven by the tick cycle.
