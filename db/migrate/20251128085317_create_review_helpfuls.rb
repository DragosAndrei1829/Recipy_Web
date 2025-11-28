class CreateReviewHelpfuls < ActiveRecord::Migration[8.1]
  def change
    create_table :review_helpfuls do |t|
      t.references :user, null: false, foreign_key: true
      t.references :comment, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :review_helpfuls, [:user_id, :comment_id], unique: true
    add_index :review_helpfuls, :comment_id
  end
end
