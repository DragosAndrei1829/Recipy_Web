class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :contact_email
      t.string :contact_phone
      t.text :contact_address
      t.string :primary_color
      t.string :secondary_color
      t.string :accent_color

      t.timestamps
    end
  end
end
