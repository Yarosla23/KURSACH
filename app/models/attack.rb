class Attack < ApplicationRecord
  enum :attack_type, {
    linear: "linear",
    exponential: "exponential"
  }

  # Тип атаки обязателен
  validates :attack_type, presence: true

  # Параметры a и b должны быть числами
  validates :a, :b, presence: true, numericality: true

  def probability_at(t)
    case attack_type
    when "linear"
      linear_probability(t)
    when "exponential"
      exponential_probability(t)
    end
  end

  # Формула (2.10)
  def linear_probability(t)
    (a * t + b).clamp(0.0, 1.0)
  end

  # Формула (2.11)
  def exponential_probability(t)
    (1 - a * Math.exp(-b * t)).clamp(0.0, 1.0)
  end

  # Формула (2.9): Z1 = 0.4, Z2 = 0.7
  def attack_level(t)
    prob = probability_at(t)
    return { level: "Низкий", color: "gray" } if prob < 0.4
    return { level: "Средний", color: "yellow" } if prob < 0.7

    { level: "Высокий", color: "red" }
  end
end
