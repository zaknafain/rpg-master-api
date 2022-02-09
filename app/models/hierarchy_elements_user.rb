# frozen_string_literal: true

# Represents the relation between the Tree and Users
class HierarchyElementsUser < ApplicationRecord
  belongs_to :user
  belongs_to :hierarchy_element

  validates :user_id, uniqueness: { scope: :hierarchy_element_id }
end
