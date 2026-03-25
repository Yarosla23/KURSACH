class Experiment < ApplicationRecord
  belongs_to :attack, class_name: "Attack", foreign_key: "attacks_id"

  has_one :adjacency_matrix, dependent: :destroy, inverse_of: :experiment
  has_many :experiment_results, dependent: :delete_all, inverse_of: :experiment
  validates :attack, presence: true

  # n — количество устройств
  validates :n, presence: true,
    numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: 8}

  # k — количество тестировщиков
  validates :k, presence: true,
    numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: 5}

  validate :k_not_greater_than_n

  # p_ai — вероятность появления атаки
  validates :p_ai, presence: true,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1}

  # p_single — базовая вероятность обнаружения p(t)
  validates :p_single, presence: true,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1}

  private

  def k_not_greater_than_n
    if k.present? && n.present? && k > n
      errors.add(:k, "не может быть больше количества устройств n")
    end
  end
end
