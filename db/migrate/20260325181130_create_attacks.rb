class CreateAttacks < ActiveRecord::Migration[8.0]
  def change
    create_table :attacks do |t|
      t.integer :attack_type
      t.float :a
      t.float :b

      t.timestamps
    end
  end
end
