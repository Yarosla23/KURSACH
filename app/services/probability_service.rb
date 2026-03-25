class ProbabilityService
  # Формула (1) — одиночное тестирование
  def self.single_test(p_t, k)
    return 0.0 if p_t <= 0 || k <= 0

    p_t * (1 - p_t)**(k - 1)
  end

  # Формула (2) — коллаборация
  def self.collab_test(p_t, k, n)
    return 0.0 if p_t <= 0 || k <= 0 || n <= 0
    comb = choose(n, k)
    comb * (p_t**k) * ((1 - p_t)**(n - k))
  end

  # Формулы (8) и (9) — с учётом противодействия
  def self.with_counteraction(prob, p_fail)
    (1 - p_fail.clamp(0.0, 1.0)) * prob
  end

  private

  # Биномиальный коэффициент C(n, k)
  def self.choose(n, k)
    return 0 if k > n || k < 0
    return 1 if k == 0 || k == n

    k = [k, n - k].min
    (1..k).inject(1) { |acc, i| acc * (n - k + i) / i }
  end
end
