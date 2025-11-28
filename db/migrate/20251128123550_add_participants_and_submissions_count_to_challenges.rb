class AddParticipantsAndSubmissionsCountToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :participants_count, :integer, default: 0, null: false
    add_column :challenges, :submissions_count, :integer, default: 0, null: false
    
    # Update existing challenges
    reversible do |dir|
      dir.up do
        Challenge.find_each do |challenge|
          challenge.update_columns(
            participants_count: challenge.challenge_participants.count,
            submissions_count: challenge.submissions.count
          )
        end
      end
    end
  end
end
