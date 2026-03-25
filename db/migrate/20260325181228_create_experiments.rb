class CreateExperiments < ActiveRecord::Migration[8.0]
  def change
    create_table :experiments do |t|
      t.references :attacks, null: false, foreign_key: true
      t.float :p_single
      t.float :p_ai
      t.integer :n
      t.integer :k

      t.timestamps
    end
  end
end
