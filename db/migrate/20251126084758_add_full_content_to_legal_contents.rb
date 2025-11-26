class AddFullContentToLegalContents < ActiveRecord::Migration[8.1]
  def change
    add_column :legal_contents, :full_content_ro, :text
    add_column :legal_contents, :full_content_en, :text
    add_column :legal_contents, :page_type, :string
  end
end
