class CreateLegalContents < ActiveRecord::Migration[8.1]
  def change
    create_table :legal_contents do |t|
      t.string :key
      t.string :title_ro
      t.string :title_en
      t.text :content_ro
      t.text :content_en
      t.integer :section_order
      t.boolean :active

      t.timestamps
    end
    add_index :legal_contents, :key, unique: true
  end
end
