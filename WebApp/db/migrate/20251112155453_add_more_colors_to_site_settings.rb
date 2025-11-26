class AddMoreColorsToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :site_settings, :navbar_color, :string, default: "#ffffff"
    add_column :site_settings, :button_color, :string, default: "#10b981"
    add_column :site_settings, :link_color, :string, default: "#059669"
    add_column :site_settings, :background_color, :string, default: "#f0fdf4"
    add_column :site_settings, :card_background, :string, default: "#ffffff"
    add_column :site_settings, :text_primary, :string, default: "#111827"
    add_column :site_settings, :text_secondary, :string, default: "#6b7280"
    add_column :site_settings, :border_color, :string, default: "#e5e7eb"
    add_column :site_settings, :success_color, :string, default: "#10b981"
    add_column :site_settings, :warning_color, :string, default: "#f59e0b"
    add_column :site_settings, :error_color, :string, default: "#ef4444"
  end
end
