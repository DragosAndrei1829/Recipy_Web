class AddRankToChallengeParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :challenge_participants, :rank, :integer, null: true
    add_index :challenge_participants, [:challenge_id, :rank] unless index_exists?(:challenge_participants, [:challenge_id, :rank])
  end
end
