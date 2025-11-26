class CreateThemes < ActiveRecord::Migration[8.1]
  def change
    create_table :themes do |t|
      t.string :name, null: false
      t.string :primary_color, default: '#10b981'
      t.string :secondary_color, default: '#14b8a6'
      t.string :accent_color, default: '#06b6d4'
      t.string :navbar_color, default: '#ffffff'
      t.string :button_color, default: '#10b981'
      t.string :link_color, default: '#059669'
      t.string :background_color, default: '#f0fdf4'
      t.string :card_background, default: '#ffffff'
      t.string :text_primary, default: '#111827'
      t.string :text_secondary, default: '#6b7280'
      t.string :border_color, default: '#e5e7eb'
      t.string :success_color, default: '#10b981'
      t.string :warning_color, default: '#f59e0b'
      t.string :error_color, default: '#ef4444'
      t.boolean :is_default, default: false

      t.timestamps
    end
  end
end
