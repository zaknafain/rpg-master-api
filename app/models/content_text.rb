# frozen_string_literal: true

# Represets the standard contents only containing text.
class ContentText < ApplicationRecord
  include VisibilityMethods

  belongs_to :hierarchy_element

  validates :content, presence: true
  validates :ordering, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { order(Arel.sql('ordering IS NULL, ordering ASC')) }

  delegate :author?, to: :parent
  delegate :players, to: :campaign

  def campaign
    parent.top_hierarchable
  end

  def parent
    hierarchy_element
  end
end
