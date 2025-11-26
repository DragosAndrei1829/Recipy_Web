class AddQuarantineFieldsToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :quarantined, :boolean, default: false, null: false
    add_column :recipes, :quarantined_at, :datetime
    add_column :recipes, :quarantine_reason, :text
    add_column :recipes, :reports_count, :integer, default: 0, null: false
    
    add_index :recipes, :quarantined
  end
end
