class AddFooterColorsToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :footer_background, :string, default: "#0f172a"
    add_column :site_settings, :footer_text, :string, default: "#ffffff"
    add_column :site_settings, :footer_link, :string, default: "#ffffff"
    add_column :site_settings, :footer_link_hover, :string, default: "#a5b4fc"
  end
end
