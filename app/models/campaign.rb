# frozen_string_literal: true

# Represents the campaign database model.
class Campaign < ApplicationRecord
  attr_accessor :email

  belongs_to :user
  has_many :campaigns_users, dependent: :delete_all
  has_many :players, through: :campaigns_users, source: :user
  has_many :hierarchy_elements, as: :hierarchable, dependent: :destroy

  validates :name, :description, presence: true
  validates :short_description, length: { maximum: 1000 }
  validates :is_public, inclusion: { in: [true, false] }

  scope :visible_to, lambda { |user_id|
    if User.find_by(id: user_id)&.admin?
      all
    else
      where(user_id:)
        .or(where(id: CampaignsUser.select(:campaign_id).where(user_id:)))
        .or(where(is_public: true))
    end
  }

  def visible_to(user = nil)
    is_public? ||
      players.include?(user) ||
      self.user == user ||
      user&.admin? == true
  end
end
