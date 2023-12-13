# frozen_string_literal: true

# Controller for handling Content
class ContentTextsController < ApplicationController
  before_action :authenticate_user!, except: :index
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

  def reorder
    contents = hierarchy_element.content_texts
    head(:bad_request) and return unless reorder_params_matching(contents.map(&:id))

    assign_ordering(contents)
    status_code = :bad_request
    ContentText.transaction do
      raise ActiveRecord::Rollback, 'not valid' unless contents.all?(&:save)

      status_code = :no_content
    end

    head status_code
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

    head(:unauthorized) and return unless admin_or_owner
  end

  def campaign
    @campaign ||= hierarchy_element.top_hierarchable
  end

  def player?
    @player = campaign.players.any? { |p| p.id == current_user&.id } if @player.nil?

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
    content_texts.select { |ct| ct.for_everyone? || (ct.for_all_players? && player?) || owner? || admin? }
  end

  def content_params
    params.require(:content_text).permit(:content, :visibility, :ordering)
  end

  def reorder_params
    params.permit(content_text_order: []).transform_values { |v| v.map(&:to_i) }
  end

  def reorder_params_matching(content_ids)
    content_ids.all? { |id| reorder_params[:content_text_order].include?(id) } &&
      reorder_params[:content_text_order].all? { |id| content_ids.include?(id) }
  end

  def assign_ordering(contents)
    reorder_params[:content_text_order].each_with_index do |id, index|
      contents.detect { |c| c.id == id }.assign_attributes(ordering: index)
    end
  end
end
