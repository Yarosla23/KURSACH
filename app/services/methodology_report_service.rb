class MethodologyReportService
  TIME_RANGE = (1..17).to_a

  ATTACK_VARIANTS = {
    1 => { linear: { a: 0.03, b: 0.01 }, exponential: { a: 0.9, b: 0.04 } },
    2 => { linear: { a: 0.035, b: 0.015 }, exponential: { a: 0.8, b: 0.045 } },
    3 => { linear: { a: 0.04, b: 0.02 }, exponential: { a: 0.7, b: 0.05 } },
    4 => { linear: { a: 0.045, b: 0.025 }, exponential: { a: 0.6, b: 0.055 } },
    5 => { linear: { a: 0.05, b: 0.03 }, exponential: { a: 0.5, b: 0.06 } },
    6 => { linear: { a: 0.055, b: 0.015 }, exponential: { a: 0.4, b: 0.065 } },
    7 => { linear: { a: 0.03, b: 0.02 }, exponential: { a: 0.5, b: 0.07 } },
    8 => { linear: { a: 0.035, b: 0.025 }, exponential: { a: 0.6, b: 0.075 } },
    9 => { linear: { a: 0.04, b: 0.03 }, exponential: { a: 0.7, b: 0.08 } },
    10 => { linear: { a: 0.045, b: 0.015 }, exponential: { a: 0.8, b: 0.085 } },
    11 => { linear: { a: 0.05, b: 0.01 }, exponential: { a: 0.9, b: 0.09 } }
  }.freeze

  SINGLE_DETECTION_VARIANTS = {
    1 => { high: 0.7, low: 0.49 },
    2 => { high: 0.75, low: 0.47 },
    3 => { high: 0.8, low: 0.45 },
    4 => { high: 0.85, low: 0.43 },
    5 => { high: 0.9, low: 0.41 },
    6 => { high: 0.7, low: 0.43 },
    7 => { high: 0.75, low: 0.45 },
    8 => { high: 0.8, low: 0.47 },
    9 => { high: 0.85, low: 0.49 },
    10 => { high: 0.9, low: 0.46 },
    11 => { high: 0.8, low: 0.43 }
  }.freeze

  ATTACK_PROFILES = [
    { key: :lin_n, name: "Лин_Н", attack_type: "linear", a: 0.03, b: 0.01 },
    { key: :lin_s, name: "Лин_С", attack_type: "linear", a: 0.045, b: 0.025 },
    { key: :lin_v, name: "Лин_В", attack_type: "linear", a: 0.06, b: 0.03 },
    { key: :exp_n, name: "Exp_Н", attack_type: "exponential", a: 0.9, b: 0.04 },
    { key: :exp_s, name: "Exp_С", attack_type: "exponential", a: 0.7, b: 0.07 },
    { key: :exp_v, name: "Exp_В", attack_type: "exponential", a: 0.5, b: 0.15 }
  ].freeze

  LEVELS = [
    { max: 0.4, name: "Низкий", color_class: "bg-slate-100" },
    { max: 0.7, name: "Средний", color_class: "bg-amber-100" },
    { max: Float::INFINITY, name: "Высокий", color_class: "bg-rose-100" }
  ].freeze

  def self.classification_table
    TIME_RANGE.map do |t|
      row = { t: t }

      ATTACK_PROFILES.each do |profile|
        value = probability_for(profile, t)
        row[profile[:key]] = value
        row[:"#{profile[:key]}_meta"] = classification_meta(value)
      end

      row
    end
  end

  def self.reference_failure_series
    ATTACK_PROFILES.map do |profile|
      {
        name: profile[:name],
        data: TIME_RANGE.map { |t| [t, probability_for(profile, t)] }
      }
    end
  end

  def self.general_list_assignment(index)
    n = (index % 11) + 1
    j = ((index + 3) % 11) + 1
    k = ((j + 3) % 11) + 1

    {
      list_index: index,
      attack_variants: [n, j, k],
      detection_variant: n,
      detection_probabilities: SINGLE_DETECTION_VARIANTS.fetch(n)
    }
  end

  def self.variant_attack_series(variant_number)
    variant = ATTACK_VARIANTS.fetch(variant_number)

    [
      {
        name: "Вариант #{variant_number} Линейная",
        data: TIME_RANGE.map { |t| [t, linear_probability(variant[:linear], t)] }
      },
      {
        name: "Вариант #{variant_number} Экспоненциальная",
        data: TIME_RANGE.map { |t| [t, exponential_probability(variant[:exponential], t)] }
      }
    ]
  end

  def self.variant_attack_series_group(variant_numbers, attack_type:)
    variant_numbers.map do |variant_number|
      variant = ATTACK_VARIANTS.fetch(variant_number)
      data = TIME_RANGE.map do |t|
        value = if attack_type == :linear
          linear_probability(variant[:linear], t)
        else
          exponential_probability(variant[:exponential], t)
        end

        [t, value]
      end

      {
        name: "Вариант #{variant_number}",
        data: data
      }
    end
  end

  def self.failure_series_for(attack)
    TIME_RANGE.map { |t| [t, attack.probability_at(t)] }
  end

  # Для пункта с p(ai)=0.33 по трем интенсивностям каждого типа атаки.
  def self.weighted_failure_series_by_type
    linear_profiles = ATTACK_PROFILES.select { |p| p[:attack_type] == "linear" }
    exp_profiles = ATTACK_PROFILES.select { |p| p[:attack_type] == "exponential" }

    {
      linear: weighted_series_for_profiles(linear_profiles),
      exponential: weighted_series_for_profiles(exp_profiles)
    }
  end

  def self.single_series_for(p_t:, k:)
    TIME_RANGE.map { |t| [t, ProbabilityService.single_test(p_t, k)] }
  end

  def self.collab_series_for(p_t:, n:, k:)
    TIME_RANGE.map { |t| [t, ProbabilityService.collab_test(p_t, k, n)] }
  end

  def self.single_counter_series_for(attack:, p_t:, p_ai:, k:)
    TIME_RANGE.map do |t|
      base_probability = ProbabilityService.single_test(p_t, k)
      p_fail = p_ai * attack.probability_at(t)
      [t, ProbabilityService.with_counteraction(base_probability, p_fail)]
    end
  end

  def self.collab_counter_series_for(attack:, p_t:, p_ai:, n:, k:)
    TIME_RANGE.map do |t|
      base_probability = ProbabilityService.collab_test(p_t, k, n)
      p_fail = p_ai * attack.probability_at(t)
      [t, ProbabilityService.with_counteraction(base_probability, p_fail)]
    end
  end

  def self.collab_grid_for(p_t:, n_range: (1..8), k_range: (1..5))
    n_range.map do |n|
      row = { n: n, values: {} }
      k_range.each do |k|
        row[:values][k] = k <= n ? ProbabilityService.collab_test(p_t, k, n) : nil
      end
      row
    end
  end

  private_class_method def self.probability_for(profile, t)
    case profile[:attack_type]
    when "linear"
      (profile[:a] * t + profile[:b]).clamp(0.0, 1.0)
    when "exponential"
      (1 - profile[:a] * Math.exp(-profile[:b] * t)).clamp(0.0, 1.0)
    else
      0.0
    end
  end

  private_class_method def self.linear_probability(params, t)
    (params[:a] * t + params[:b]).clamp(0.0, 1.0)
  end

  private_class_method def self.exponential_probability(params, t)
    (1 - params[:a] * Math.exp(-params[:b] * t)).clamp(0.0, 1.0)
  end

  private_class_method def self.weighted_series_for_profiles(profiles)
    weight = 1.0 / 3
    TIME_RANGE.map do |t|
      value = profiles.sum { |profile| weight * probability_for(profile, t) }
      [t, value.clamp(0.0, 1.0)]
    end
  end

  private_class_method def self.classification_meta(value)
    LEVELS.find { |level| value < level[:max] }
  end
end
