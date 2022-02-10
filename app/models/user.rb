# frozen_string_literal: true

# Represents the Users Database Model
class User < ApplicationRecord
  has_many :campaigns, dependent: :destroy

  has_many :campaigns_users,  dependent: :delete_all
  has_many :campaigns_played, through: :campaigns_users, source: :campaign

  has_many :hierarchy_elements_users, dependent: :delete_all
  has_many :content_texts_users,      dependent: :delete_all

  has_secure_password

  validates :name, presence: true, length: { maximum: 30 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 },
                       if: :password_validation_is_needed?
  validate  :password_comparison, if: :password_validation_is_needed?

  after_validation { errors.delete(:password_digest) }
  before_save :downcase_email

  def to_token_payload
    { sub: id, name: }
  end

  def players
    campaigns.includes(:players)
             .map(&:players)
             .flatten
             .uniq(&:email)
             .sort! { |x, y| x.email <=> y.email }
  end

  private

  def password_validation_is_needed?
    !(persisted? && password.blank?)
  end

  def password_comparison
    return if password == password_confirmation

    errors.add(:password_confirmation, 'passwords_not_matching')
  end

  def downcase_email
    email.downcase!
  end
end

# Represents Users which are Admins
class Admin < User
  default_scope { where(admin: true) }
end
