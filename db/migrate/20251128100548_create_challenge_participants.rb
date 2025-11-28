class CreateChallengeParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :challenge_participants do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: true, foreign_key: true # Optional - can join without submitting
      t.datetime :submitted_at
      t.string :status, null: false, default: "joined" # joined, submitted, disqualified, winner
      t.decimal :score, precision: 5, scale: 2
      t.integer :rank

      t.timestamps
    end
    
    add_index :challenge_participants, [:challenge_id, :user_id], unique: true
    add_index :challenge_participants, [:challenge_id, :status]
    add_index :challenge_participants, [:challenge_id, :rank]
  end
end
