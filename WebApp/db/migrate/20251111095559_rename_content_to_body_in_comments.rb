class RenameContentToBodyInComments < ActiveRecord::Migration[8.1]
  def change
    rename_column :comments, :content, :body
  end

end
