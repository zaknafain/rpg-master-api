# frozen_string_literal: true

# Controller for handling the tree structure
class HierarchyElementsController < ApplicationController
  before_action :authenticate_user, except: :index
  before_action :authenticate_owner, except: :index

  def index
    render json: filter_elements(hierarchable.hierarchy_elements)
  end

  def create
    merged_params = element_params.merge(hierarchable_id:, hierarchable_type:)
    new_element = hierarchable.hierarchy_elements.build(merged_params)

    if new_element.save
      render json: new_element, status: :created
    else
      head :bad_request
    end
  end

  def update
    if hierarchable.update(element_params)
      head :no_content
    else
      head :bad_request
    end
  end

  def destroy
    if hierarchable.destroy
      head :no_content
    else
      head :bad_request
    end
  end

  private

  def authenticate_owner
    admin_or_owner = current_user.id == campaign.user_id || current_user.admin?

    head(:unauthorized) and return unless admin_or_owner
  end

  def campaign
    @campaign ||= hierarchable_type == 'Campaign' ? hierarchable : hierarchable.top_hierarchable
  end

  def player?
    @player = campaign.players.select { |p| p.id == current_user&.id }.present? if @player.nil?

    @player
  end

  def owner?
    @owner = campaign.user_id == current_user&.id if @owner.nil?

    @owner
  end

  def admin?
    @admin = current_user&.admin? if @admin.nil?

    @admin
  end

  def hierarchable
    @hierarchable ||= case hierarchable_type
                      when 'Campaign'
                        Campaign.visible_to(current_user&.id).find(hierarchable_id)
                      when 'HierarchyElement'
                        find_element(hierarchable_id)
                      else
                        find_element(params[:id])
                      end
  end

  def find_element(element_id)
    element = HierarchyElement.find(element_id)
    raise ActiveRecord::RecordNotFound, nil unless element.visible_to(current_user)

    element
  end

  def filter_elements(elements)
    elements.select { |e| e.for_everyone? || (e.for_all_players? && player?) || owner? || admin? }
  end

  def hierarchable_type
    params[:filter] && params[:filter][:hierarchable_type]
  end

  def hierarchable_id
    params[:filter] && params[:filter][:hierarchable_id]
  end

  def element_params
    params.require(:hierarchy_element).permit(:name, :visibility, :description)
  end
end
