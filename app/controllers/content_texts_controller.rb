# frozen_string_literal: true

class ContentTextsController < ApplicationController
  before_action :authenticate_user, except: :index
  before_action :authenticate_owner, except: :index

  def index
    render json: filter_content(hierarchy_element.content_texts)
  end

  def create
    merged_params = content_params.merge(hierarchy_element_id: hierarchy_element.id)
    new_content = hierarchy_element.content_texts.build(merged_params)

    if new_content.save
      render json: new_content, status: :created
    else
      head :bad_request
    end
  end

  def update
    if content_text.update(content_params)
      head :no_content
    else
      head :bad_request
    end
  end

  def destroy
    if content_text.destroy
      head :no_content
    else
      head :bad_request
    end
  end

  private

  def authenticate_owner
    admin_or_owner = current_user.id == campaign.user_id || current_user.admin?

    head(:forbidden) and return unless admin_or_owner
  end

  def campaign
    @campaign ||= hierarchy_element.top_hierarchable
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

  def hierarchy_element
    @hierarchy_element ||= if params[:hierarchy_element_id]
                             find_element(params[:hierarchy_element_id])
                           else
                             content_text.hierarchy_element
                           end
  end

  def find_element(element_id)
    element = HierarchyElement.find(element_id)
    raise ActiveRecord::RecordNotFound, nil unless element.visible_to(current_user)

    element
  end

  def content_text
    @content_text ||= find_content(params[:id])
  end

  def find_content(content_id)
    content = ContentText.find(content_id)
    raise ActiveRecord::RecordNotFound, nil unless content.visible_to(current_user)

    content
  end

  def filter_content(content_texts)
    content_texts.select { |ct| ct.for_everyone? || ct.for_all_players? && player? || owner? || admin? }
  end

  def content_params
    params.require(:content_text).permit(:content, :visibility, :ordering)
  end
end
