class ExperimentRuntimeComparisonService
  def initialize(experiment)
    @experiment = experiment
    @attack = experiment.attack
  end

  def call
    rows = build_rows

    {
      rows: rows,
      base_single: base_single_probability,
      base_collab: base_collab_probability,
      series: build_series(rows),
      insights: build_insights(rows)
    }
  end

  private

  def build_rows
    ExperimentRunner::TIME_RANGE.map do |t|
      attack_prob = @attack.probability_at(t)
      p_fail = @experiment.p_ai * attack_prob
      single_counter = ProbabilityService.with_counteraction(base_single_probability, p_fail)
      collab_counter = ProbabilityService.with_counteraction(base_collab_probability, p_fail)

      {
        t: t,
        p_attack: attack_prob,
        p_fail: p_fail,
        single_base: base_single_probability,
        collab_base: base_collab_probability,
        single_counter: single_counter,
        collab_counter: collab_counter,
        single_loss: base_single_probability - single_counter,
        collab_loss: base_collab_probability - collab_counter,
        counter_advantage: collab_counter - single_counter
      }
    end
  end

  def build_series(rows)
    {
      single: [
        {name: "Single без противодействия", data: rows.map { |row| [row[:t], row[:single_base]] }},
        {name: "Single с противодействием", data: rows.map { |row| [row[:t], row[:single_counter]] }},
        {name: "pA(отк)", data: rows.map { |row| [row[:t], row[:p_fail]] }}
      ],
      collab: [
        {name: "Collab без противодействия", data: rows.map { |row| [row[:t], row[:collab_base]] }},
        {name: "Collab с противодействием", data: rows.map { |row| [row[:t], row[:collab_counter]] }},
        {name: "pA(отк)", data: rows.map { |row| [row[:t], row[:p_fail]] }}
      ],
      counter_compare: [
        {name: "Single с противодействием", data: rows.map { |row| [row[:t], row[:single_counter]] }},
        {name: "Collab с противодействием", data: rows.map { |row| [row[:t], row[:collab_counter]] }}
      ]
    }
  end

  def build_insights(rows)
    max_fail = rows.max_by { |row| row[:p_fail] }
    max_single_loss = rows.max_by { |row| row[:single_loss] }
    max_collab_loss = rows.max_by { |row| row[:collab_loss] }
    max_advantage = rows.max_by { |row| row[:counter_advantage] }
    avg_single_counter = average(rows, :single_counter)
    avg_collab_counter = average(rows, :collab_counter)
    better_steps = rows.count { |row| row[:counter_advantage] > 0 }

    [
      "Для введенных параметров эксперимента базовая вероятность одиночного обнаружения без противодействия составляет #{format_value(base_single_probability)}, а базовая вероятность коллаборационного обнаружения — #{format_value(base_collab_probability)}.",
      "Средняя вероятность обнаружения с учетом противодействия равна #{format_value(avg_single_counter)} для режима Single и #{format_value(avg_collab_counter)} для режима Collab. Коллаборационный режим превосходит одиночный на #{better_steps} из #{rows.size} временных шагов.",
      "Максимальная вероятность отказа тестирования pA(отк) достигается на шаге t=#{max_fail[:t]} и составляет #{format_value(max_fail[:p_fail])}. В этой области влияние атаки на итоговые вероятности обнаружения наиболее заметно.",
      "Наибольшее снижение вероятности одиночного обнаружения наблюдается на шаге t=#{max_single_loss[:t]} и составляет #{format_value(max_single_loss[:single_loss])}. Для коллаборационной стратегии максимальное снижение достигается на шаге t=#{max_collab_loss[:t]} и составляет #{format_value(max_collab_loss[:collab_loss])}.",
      "Наибольший выигрыш коллаборационной стратегии при текущих параметрах достигается на шаге t=#{max_advantage[:t]} и составляет #{format_value(max_advantage[:counter_advantage])}. Это значение показывает, насколько режим Collab устойчивее одиночного обнаружения в рамках заданного эксперимента."
    ]
  end

  def base_single_probability
    @base_single_probability ||= ProbabilityService.single_test(@experiment.p_single, @experiment.k)
  end

  def base_collab_probability
    @base_collab_probability ||= ProbabilityService.collab_test(@experiment.p_single, @experiment.k, @experiment.n)
  end

  def average(rows, key)
    rows.sum { |row| row[key] } / rows.size.to_f
  end

  def format_value(value)
    format("%.4f", value)
  end
end
