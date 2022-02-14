# frozen_string_literal: true

# Controller for handling Campaigns
class CampaignsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :authenticate_owner, only: %i[update destroy]

  def index
    render json: Campaign.visible_to(current_user&.id)
  end

  def show
    render json: campaign
  end

  def create
    new_campaign = current_user.campaigns.build(campaign_params)

    if new_campaign.save
      render json: new_campaign, status: :created
    else
      head :bad_request
    end
  end

  def update
    if campaign.update(campaign_params)
      head :no_content
    else
      head :bad_request
    end
  end

  def destroy
    if campaign.destroy
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
    @campaign ||= Campaign.visible_to(current_user).find(params['id'])
  end

  def campaign_params
    params.require(:campaign).permit(:name, :short_description, :description, :is_public)
  end
end
