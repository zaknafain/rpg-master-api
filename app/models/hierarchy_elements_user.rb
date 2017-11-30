class HierarchyElementsUser < ApplicationRecord

  belongs_to :user
  belongs_to :hierarchy_element

  validates :user_id, uniqueness: { scope: :hierarchy_element_id }
  validates :user, :hierarchy_element, presence: true

end
