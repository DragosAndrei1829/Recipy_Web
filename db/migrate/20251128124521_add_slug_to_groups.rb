class AddSlugToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :slug, :string
    add_index :groups, :slug, unique: true
  end
end
