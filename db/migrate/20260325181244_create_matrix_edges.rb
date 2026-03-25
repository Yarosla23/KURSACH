class CreateMatrixEdges < ActiveRecord::Migration[8.0]
  def change
    create_table :matrix_edges do |t|
      t.references :adjacency_matrix, null: false, foreign_key: true
      t.integer :x
      t.integer :y
      t.integer :weight

      t.timestamps
    end
  end
end
