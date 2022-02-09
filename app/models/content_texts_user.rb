# frozen_string_literal: true

# Represents the relation between Content and Users
class ContentTextsUser < ApplicationRecord
  belongs_to :user
  belongs_to :content_text

  validates :user_id, uniqueness: { scope: :content_text_id }
end
