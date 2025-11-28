# frozen_string_literal: true

class ReviewHelpful < ApplicationRecord
  belongs_to :user
  belongs_to :comment, counter_cache: :helpful_count

  validates :user_id, uniqueness: { scope: :comment_id, message: "Ai marcat deja această recenzie ca utilă" }
end

