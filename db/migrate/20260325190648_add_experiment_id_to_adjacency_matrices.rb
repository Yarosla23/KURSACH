class AddExperimentIdToAdjacencyMatrices < ActiveRecord::Migration[8.0]
  def change
    add_reference :adjacency_matrices, :experiment, null: false, foreign_key: true
  end
end
