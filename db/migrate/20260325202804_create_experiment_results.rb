class CreateExperimentResults < ActiveRecord::Migration[8.0]
  def change
    create_table :experiment_results do |t|
      t.references :experiment, null: false, foreign_key: true
      t.integer :t
      t.float :p_attack
      t.float :p_single
      t.float :p_collab
      t.float :p_single_counter
      t.float :p_collab_counter

      t.timestamps
    end
  end
end
