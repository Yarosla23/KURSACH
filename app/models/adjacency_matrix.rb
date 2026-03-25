class AdjacencyMatrix < ApplicationRecord
  belongs_to :experiment, inverse_of: :adjacency_matrix
  has_many :matrix_edges, dependent: :destroy

  validates :data, presence: true
end
