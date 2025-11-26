class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.string :reason, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.text :admin_notes
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at

      t.timestamps
    end
    
    add_index :reports, [:reportable_type, :reportable_id, :reporter_id], unique: true, name: 'index_reports_unique_per_reporter'
    add_index :reports, :status
  end
end
