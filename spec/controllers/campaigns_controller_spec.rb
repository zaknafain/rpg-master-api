# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CampaignsController do
  let!(:public_campaign)  { FactoryBot.create(:campaign) }
  let!(:private_campaign) { FactoryBot.create(:campaign, is_public: false) }
  let!(:played_campaign)  { FactoryBot.create(:campaign, is_public: false, players: [owner]) }
  let(:owned_campaign)    { FactoryBot.create(:campaign, is_public: false) }
  let(:owner)             { owned_campaign.user }
  let(:user)              { FactoryBot.create(:user) }
  let(:admin)             { FactoryBot.create(:user, :admin) }

  describe 'GET index' do
    it 'returns status 200 and the correct schema' do
      get :index

      expect(response.status).to eq(200)
      expect(response.body).to   of_correct_schema?(:campaign, nil, false)
    end

    it 'returns public, played and owned campaigns' do
      request.headers.merge! auth_header(owner)
      get :index

      expect(response.body).to include(public_campaign.name)
      expect(response.body).to include(played_campaign.name)
      expect(response.body).to include(owned_campaign.name)
      expect(response.body).not_to include(private_campaign.name)
    end

    it 'returns all campaigns for admins' do
      request.headers.merge! auth_header(admin)
      get :index

      expect(response.body).to include(public_campaign.name)
      expect(response.body).to include(played_campaign.name)
      expect(response.body).to include(owned_campaign.name)
      expect(response.body).to include(private_campaign.name)
    end

    it 'returns public campaigns even for not signed in users' do
      get :index

      expect(response.body).to include(public_campaign.name)
      expect(response.body).not_to include(played_campaign.name)
      expect(response.body).not_to include(owned_campaign.name)
      expect(response.body).not_to include(private_campaign.name)
    end
  end

  describe 'GET show' do
    it 'returns status 200 and the correct schema' do
      get :show, params: { id: public_campaign.id }

      expect(response.status).to eq(200)
      expect(response.body).to of_correct_schema?(:campaign, nil, false)
    end

    it 'returns public campaigns even for not logged in users' do
      get :show, params: { id: public_campaign.id }

      expect(response.body).to include(public_campaign.name)
    end

    it 'does not return private campaigns if the user is no player, admin or owner' do
      request.headers.merge! auth_header(owner)
      get :show, params: { id: private_campaign.id }

      expect(response.status).to eq(404)
    end

    it 'returns played campaigns for players' do
      request.headers.merge! auth_header(owner)
      get :show, params: { id: played_campaign.id }

      expect(response.body).to include(played_campaign.name)
    end

    it 'returns owned campaigns for owners' do
      request.headers.merge! auth_header(owner)
      get :show, params: { id: owned_campaign.id }

      expect(response.body).to include(owned_campaign.name)
    end

    it 'returns all campaigns for admins' do
      request.headers.merge! auth_header(admin)
      get :show, params: { id: private_campaign.id }

      expect(response.body).to include(private_campaign.name)
    end
  end

  describe 'POST create' do
    let(:create_params) do
      {
        name: 'Foo Campaign',
        short_description: 'Super short',
        description: 'Somewhat longer description',
        is_public: false
      }
    end

    it 'needs authentication' do
      post :create, params: { campaign: create_params }

      expect(response.status).to eq(401)
    end

    it 'returns status 201 and the created campaign' do
      request.headers.merge! auth_header(owner)
      post :create, params: { campaign: create_params }

      expect(response.status).to eq(201)
      expect(response.body).to of_correct_schema?(:campaign, owner.id, owner.admin?)
    end

    it 'creates a new campaign for the signed in user with the given parameters' do
      request.headers.merge! auth_header(owner)

      expect { post :create, params: { campaign: create_params } }.to change(Campaign, :count).by(1)

      campaign = Campaign.order(created_at: :asc).last
      expect(campaign.user_id).to eq(owner.id)
      create_params.each do |key, value|
        expect(campaign.send(key)).to eq(value)
      end
    end

    it 'returns a 400 and does not create a campaign on invalid params' do
      request.headers.merge! auth_header(owner)

      expect { post :create, params: { campaign: create_params.except(:name) } }.not_to change(Campaign, :count)

      expect(response.status).to eq(400)
    end

    it 'does not allow to create campaigns for other users' do
      request.headers.merge! auth_header(owner)

      params = create_params.merge(user_id: user.id)
      expect { post :create, params: { campaign: params } }.to change(Campaign, :count).by(1)
      campaign = Campaign.order(created_at: :asc).last

      expect(campaign.user_id).to eq(owner.id)
    end
  end

  describe 'PUT update' do
    let(:update_params) do
      {
        name: 'Foo Campaign',
        short_description: 'Super short',
        description: 'Somewhat longer description',
        is_public: true
      }
    end

    it 'needs authentication' do
      put :update, params: { id: owned_campaign.id, campaign: update_params }

      expect(response.status).to eq(401)
    end

    it 'returns status 204' do
      request.headers.merge! auth_header(owner)
      put :update, params: { id: owned_campaign.id, campaign: update_params }

      expect(response.status).to eq(204)
    end

    it 'returns a 404 on not visible campaigns' do
      request.headers.merge! auth_header(owner)
      put :update, params: { id: private_campaign.id, campaign: update_params }

      expect(response.status).to eq(404)
    end

    it 'updates the campaign for the signed in owner with the given parameters' do
      request.headers.merge! auth_header(owner)

      put :update, params: { id: owned_campaign.id, campaign: update_params }

      owned_campaign.reload
      update_params.each do |key, value|
        expect(owned_campaign.send(key)).to eq(value)
      end
    end

    it 'returns a 400 and does not update the campaign on invalid params' do
      request.headers.merge! auth_header(owner)

      put :update, params: { id: owned_campaign.id, campaign: update_params.merge(name: '') }

      owned_campaign.reload
      update_params.each do |key, value|
        expect(owned_campaign.send(key)).not_to eq(value)
      end
      expect(response.status).to eq(400)
    end

    it 'does not allow to update campaigns for other users' do
      request.headers.merge! auth_header(owner)

      put :update, params: { id: played_campaign.id, campaign: update_params }

      played_campaign.reload
      update_params.each do |key, value|
        expect(played_campaign.send(key)).not_to eq(value)
      end
      expect(response.status).to eq(401)
    end

    it 'does allow admins to update campaigns for other users' do
      request.headers.merge! auth_header(admin)

      put :update, params: { id: owned_campaign.id, campaign: update_params }

      owned_campaign.reload
      update_params.each do |key, value|
        expect(owned_campaign.send(key)).to eq(value)
      end
      expect(response.status).to eq(204)
    end

    it 'does not allow to update the user_id' do
      request.headers.merge! auth_header(owner)

      params = update_params.merge(user_id: user.id)
      put :update, params: { id: owned_campaign.id, campaign: params }
      owned_campaign.reload

      expect(owned_campaign.user_id).to eq(owner.id)
    end
  end

  describe 'DELETE destroy' do
    it 'needs authentication' do
      delete :destroy, params: { id: owned_campaign.id }

      expect(response.status).to eq(401)
    end

    it 'returns status 204' do
      request.headers.merge! auth_header(owner)
      delete :destroy, params: { id: owned_campaign.id }

      expect(response.status).to eq(204)
    end

    it 'destroys the requested campaign' do
      request.headers.merge! auth_header(owner)

      expect { delete :destroy, params: { id: owned_campaign.id } }.to change(Campaign, :count).by(-1)
    end

    it 'does not allow do destroy campaigns of other users' do
      request.headers.merge! auth_header(owner)

      expect { delete :destroy, params: { id: private_campaign.id } }.not_to change(Campaign, :count)
      expect(response.status).to eq(404)
    end

    it 'does allow admins do destroy campaigns of other users' do
      request.headers.merge! auth_header(admin)

      expect { delete :destroy, params: { id: owned_campaign.id } }.to change(Campaign, :count).by(-1)
      expect(response.status).to eq(204)
    end
  end
end
