class AddThemeToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :theme_id, :integer
  end
end
