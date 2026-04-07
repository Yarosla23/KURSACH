class ExperimentComparisonService
  DEFAULT_ASSIGNMENT_INDEX = 1

  def initialize(experiment, assignment_index: DEFAULT_ASSIGNMENT_INDEX)
    @experiment = experiment
    @attack = experiment.attack
    @assignment_index = assignment_index
  end

  def call
    probabilities = detection_probabilities
    rows = build_rows(probabilities)

    {
      detection_probabilities: probabilities,
      rows: rows,
      series: build_series(rows, probabilities),
      insights: build_insights(rows, probabilities)
    }
  end

  private

  def detection_probabilities
    MethodologyReportService.general_list_assignment(@assignment_index)[:detection_probabilities]
  end

  def build_rows(probabilities)
    ExperimentRunner::TIME_RANGE.map do |t|
      attack_prob = @attack.probability_at(t)
      p_fail = @experiment.p_ai * attack_prob
      high_detect = counter_probability(probabilities[:high], mode: :collab, p_fail: p_fail)
      low_detect = counter_probability(probabilities[:low], mode: :collab, p_fail: p_fail)

      {
        t: t,
        p_attack: attack_prob,
        p_fail: p_fail,
        high_detect: high_detect,
        low_detect: low_detect,
        detection_gap: high_detect - low_detect
      }
    end
  end

  def counter_probability(p_t, mode:, p_fail:)
    base_probability = case mode
    when :single
      ProbabilityService.single_test(p_t, @experiment.k)
    when :collab
      ProbabilityService.collab_test(p_t, @experiment.k, @experiment.n)
    else
      0.0
    end

    ProbabilityService.with_counteraction(base_probability, p_fail)
  end

  def build_series(rows, probabilities)
    {
      high: [
        {name: "Вероятность атаки pA(t)", data: rows.map { |row| [row[:t], row[:p_attack]] }},
        {name: "Вероятность обнаружения P(pA(t), p(t,k))", data: rows.map { |row| [row[:t], row[:high_detect]] }}
      ],
      low: [
        {name: "Вероятность атаки pA(t)", data: rows.map { |row| [row[:t], row[:p_attack]] }},
        {name: "Вероятность обнаружения P(pA(t), p(t,k))", data: rows.map { |row| [row[:t], row[:low_detect]] }}
      ]
    }
  end

  def build_insights(rows, probabilities)
    peak_attack = rows.max_by { |row| row[:p_attack] }
    high_avg_detect = average(rows, :high_detect)
    low_avg_detect = average(rows, :low_detect)
    best_gap = rows.max_by { |row| row[:detection_gap] }
    medium_step = rows.find { |row| row[:p_attack] >= 0.4 }&.fetch(:t, nil)
    high_step = rows.find { |row| row[:p_attack] >= 0.7 }&.fetch(:t, nil)

    [
      "В режиме p(t)=#{probabilities[:high]} средняя вероятность обнаружения при коллаборационной стратегии составляет #{format_value(high_avg_detect)}. Это значение выше, чем в режиме p(t)=#{probabilities[:low]}, где средняя вероятность обнаружения равна #{format_value(low_avg_detect)}.",
      "Переход от режима p(t)=#{probabilities[:high]} к режиму p(t)=#{probabilities[:low]} уменьшает вероятность обнаружения на каждом шаге моделирования. Наибольшая разница между этими режимами наблюдается при t=#{best_gap[:t]} и составляет #{format_value(best_gap[:detection_gap])}.",
      "Максимальная вероятность атаки pA(t) достигается на шаге t=#{peak_attack[:t]} и составляет #{format_value(peak_attack[:p_attack])}.#{attack_level_sentence(medium_step, high_step)}",
      "Так как вероятность атаки с ростом времени увеличивается, а итоговая вероятность обнаружения рассчитывается с учетом противодействия, для обоих режимов p(t) на поздних шагах моделирования наблюдается снижение эффективности обнаружения."
    ]
  end

  def attack_level_sentence(medium_step, high_step)
    parts = []
    parts << " Уровень средней интенсивности атаки достигается начиная с t=#{medium_step}." if medium_step
    parts << " Высокий уровень достигается начиная с t=#{high_step}." if high_step
    parts.join
  end

  def average(rows, key)
    rows.sum { |row| row[key] } / rows.size.to_f
  end

  def format_value(value)
    format("%.4f", value)
  end
end
