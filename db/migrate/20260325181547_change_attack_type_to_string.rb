class ChangeAttackTypeToString < ActiveRecord::Migration[8.0]
  def change
    change_column :attacks, :attack_type, :string
  end
end
