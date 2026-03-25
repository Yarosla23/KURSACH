class CreateAdjacencyMatrices < ActiveRecord::Migration[8.0]
  def change
    create_table :adjacency_matrices do |t|
      t.json :data

      t.timestamps
    end
  end
end
