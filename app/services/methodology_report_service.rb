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

  def self.variant_attack_surface_config(assignment_index: 1)
    assignment = general_list_assignment(assignment_index)
    z_labels = []
    values = []

    assignment[:attack_variants].each do |variant_number|
      variant = ATTACK_VARIANTS.fetch(variant_number)
      [:linear, :exponential].each do |attack_type|
        params = variant.fetch(attack_type)
        z_labels << "#{attack_type == :linear ? "L" : "E"}#{variant_number}"
        values << TIME_RANGE.map do |t|
          attack_type == :linear ? linear_probability(params, t) : exponential_probability(params, t)
        end
      end
    end

    surface_chart_config(
      title: "3D-поверхность профилей атак для варианта #{assignment_index}",
      x_labels: TIME_RANGE.map(&:to_s),
      z_labels: z_labels,
      values: values,
      x_title: "t",
      z_title: "v",
      y_title: "P_A"
    )
  end

  def self.attack_surface_config(attack)
    p_ai_values = [0.1, 0.33, 0.66, 1.0]
    values = p_ai_values.map do |p_ai|
      TIME_RANGE.map { |t| (p_ai * attack.probability_at(t)).clamp(0.0, 1.0) }
    end

    surface_chart_config(
      title: "3D-профиль атаки ##{attack.id}: p(ai)*pA(t)",
      x_labels: TIME_RANGE.map(&:to_s),
      z_labels: p_ai_values.map { |value| format("%.2f", value) },
      values: values,
      x_title: "t",
      z_title: "p_i",
      y_title: "P_F"
    )
  end

  def self.collab_probability_surface_config(p_t:, title: nil)
    values = (1..8).map do |n|
      (1..5).map { |k| k <= n ? ProbabilityService.collab_test(p_t, k, n) : 0.0 }
    end

    surface_chart_config(
      title: title || "3D-поверхность P(p(t,k)) при p(t)=#{format("%.2f", p_t)}",
      x_labels: (1..5).map(&:to_s),
      z_labels: (1..8).map(&:to_s),
      values: values,
      x_title: "k",
      z_title: "n",
      y_title: "P"
    )
  end

  def self.experiment_surface_config(experiment:, results:)
    rows = Array(results)
    values = [
      rows.map { |result| result.p_attack.to_f },
      rows.map { |result| (experiment.p_ai.to_f * result.p_attack.to_f).clamp(0.0, 1.0) },
      rows.map { |result| result.p_single.to_f },
      rows.map { |result| result.p_single_counter.to_f },
      rows.map { |result| result.p_collab.to_f },
      rows.map { |result| result.p_collab_counter.to_f }
    ]

    surface_chart_config(
      title: "3D-результаты эксперимента ##{experiment.id}",
      x_labels: rows.map { |result| result.t.to_s },
      z_labels: ["A", "F", "S", "S'", "C", "C'"],
      values: values,
      x_title: "t",
      z_title: "q",
      y_title: "P"
    )
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

  private_class_method def self.surface_chart_config(title:, x_labels:, z_labels:, values:, x_title:, z_title:, y_title:)
    normalized_values = Array(values).map do |row|
      Array(row).map { |value| value.nil? ? nil : value.to_f }
    end
    numeric_values = normalized_values.flatten.compact
    y_min, y_max = adaptive_probability_range(numeric_values)

    {
      title: title,
      xLabels: x_labels.map(&:to_s),
      zLabels: z_labels.map(&:to_s),
      xTitle: x_title,
      zTitle: z_title,
      yTitle: y_title,
      yMin: y_min,
      yMax: y_max,
      values: normalized_values
    }
  end

  private_class_method def self.adaptive_probability_range(values)
    return [0.0, 1.0] if values.empty?

    raw_min = values.min
    raw_max = values.max
    spread = raw_max - raw_min

    min_value, max_value =
      if spread.abs < 1e-9
        padding = [raw_max.abs * 0.15, 0.001].max
        [raw_min - padding, raw_max + padding]
      else
        padding = [spread * 0.12, raw_max.abs * 0.03, 0.001].max
        [raw_min - padding, raw_max + padding]
      end

    [[min_value, 0.0].max, [max_value, 1.0].min]
  end
end
