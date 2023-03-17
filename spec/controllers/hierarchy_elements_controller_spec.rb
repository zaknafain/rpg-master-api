# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HierarchyElementsController do
  let(:private_campaign)  { FactoryBot.create(:campaign, :with_elements, is_public: false) }
  let(:public_campaign)   { FactoryBot.create(:campaign, :with_elements, :with_player) }
  let(:public_element)    { public_campaign.hierarchy_elements.find_by(visibility: :for_everyone) }
  let(:player_element)    { public_campaign.hierarchy_elements.find_by(visibility: :for_all_players) }
  let(:invisible_element) { public_campaign.hierarchy_elements.find_by(visibility: :author_only) }
  let(:player)            { public_campaign.players.first }
  let(:owner)             { public_campaign.user }
  let(:user)              { FactoryBot.create(:user) }
  let(:admin)             { FactoryBot.create(:user, :admin) }
  let(:filter_params)     { { hierarchable_type: 'Campaign', hierarchable_id: public_campaign.id } }

  describe 'GET index' do
    it 'returns status 200 and the correct schema' do
      get :index, params: { filter: filter_params }

      expect(response.status).to eq(200)
      expect(response.body).to of_correct_schema?(:hierarchy_element, nil, false)
    end

    it 'returns all hierarchable elements which are for everyone if not signed in' do
      get :index, params: { filter: filter_params }

      expect(response.body).to     include(public_element.id.to_s)
      expect(response.body).not_to include(player_element.id.to_s)
      expect(response.body).not_to include(invisible_element.id.to_s)
    end

    it 'returns all hierarchable elements which are for everyone if requested as registered user' do
      request.headers.merge! auth_header(user)
      get :index, params: { filter: filter_params }

      expect(response.body).to     include(public_element.id.to_s)
      expect(response.body).not_to include(player_element.id.to_s)
      expect(response.body).not_to include(invisible_element.id.to_s)
    end

    it 'returns elements for players if requested as player' do
      request.headers.merge! auth_header(player)
      get :index, params: { filter: filter_params }

      expect(response.body).to     include(public_element.id.to_s)
      expect(response.body).to     include(player_element.id.to_s)
      expect(response.body).not_to include(invisible_element.id.to_s)
    end

    it 'returns all elements for owners' do
      request.headers.merge! auth_header(owner)
      get :index, params: { filter: filter_params }

      expect(response.body).to include(public_element.id.to_s)
      expect(response.body).to include(player_element.id.to_s)
      expect(response.body).to include(invisible_element.id.to_s)
    end

    it 'returns all elements for admins' do
      request.headers.merge! auth_header(admin)
      get :index, params: { filter: filter_params }

      expect(response.body).to include(public_element.id.to_s)
      expect(response.body).to include(player_element.id.to_s)
      expect(response.body).to include(invisible_element.id.to_s)
    end

    it 'returns a 404 if the filter param is missing' do
      get :index

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the filter param is empty' do
      get :index, params: { filter: {} }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the filters campaign id is not existing' do
      public_campaign
      campaign_id = Campaign.last.id

      get :index, params: { filter: filter_params.merge(hierarchable_id: campaign_id + 1) }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the filters type and id combination is not matching' do
      get :index, params: { filter: { hierarchable_type: 'HierarchyElement', hierarchable_id: public_campaign.id } }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the campaign is not visible to the user' do
      get :index, params: {
        filter: { hierarchable_type: 'Campaign', hierarchable_id: private_campaign.id }
      }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the hierarchy element is not visible to the user' do
      get :index, params: {
        filter: { hierarchable_type: 'HierarchyElement', hierarchable_id: invisible_element.id }
      }

      expect(response.status).to eq(404)
    end
  end

  describe 'POST create' do
    let(:create_params) do
      {
        name: 'Foo Campaign',
        description: 'Somewhat longer description',
        visibility: 'author_only'
      }
    end
    let(:params) { { hierarchy_element: create_params, filter: filter_params } }

    it 'needs authentication' do
      post(:create, params:)

      expect(response.status).to eq(401)
    end

    it 'returns status 201 and the created element' do
      request.headers.merge! auth_header(owner)
      post(:create, params:)

      expect(response.status).to eq(201)
      expect(response.body).to of_correct_schema?(:hierarchy_element, owner.id, owner.admin?)
    end

    it 'creates a new element for the given filter' do
      request.headers.merge! auth_header(owner)

      expect { post :create, params: }.to change(HierarchyElement, :count).by(1)

      element = public_campaign.hierarchy_elements.order(created_at: :asc).last
      create_params.each do |key, value|
        expect(element.send(key)).to eq(value)
      end
    end

    it 'returns a 404 if the filter param is missing' do
      request.headers.merge! auth_header(owner)
      post :create, params: { hierarchy_element: create_params }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the filter param is empty' do
      request.headers.merge! auth_header(owner)
      post :create, params: { hierarchy_element: create_params, filter: {} }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the filters campaign id is not existing' do
      request.headers.merge! auth_header(owner)
      campaign_id = Campaign.last.id
      post :create, params: {
        hierarchy_element: create_params, filter: filter_params.merge(hierarchable_id: campaign_id + 1)
      }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the filters type and id combination is not matching' do
      request.headers.merge! auth_header(owner)
      post :create, params: {
        hierarchy_element: create_params, filter: filter_params.merge(hierarchable_type: 'HierarchyElement')
      }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the campaign is not visible to the user' do
      request.headers.merge! auth_header(owner)
      post :create, params: {
        hierarchy_element: create_params, filter: filter_params.merge(hierarchable_id: private_campaign.id)
      }

      expect(response.status).to eq(404)
    end

    it 'returns a 401 if the user does not own the campaign' do
      request.headers.merge! auth_header(user)
      post :create, params: {
        hierarchy_element: create_params, filter: filter_params.merge(hierarchable_id: public_campaign.id)
      }

      expect(response.status).to eq(401)
    end

    it 'returns a 400 and does not create an element on invalid params' do
      params[:hierarchy_element][:name] = ''
      request.headers.merge! auth_header(owner)

      expect { post :create, params: }.not_to change(HierarchyElement, :count)
      expect(response.status).to eq(400)
    end
  end

  describe 'PUT update' do
    let(:update_params) do
      {
        name: 'Foo Campaign',
        description: 'Somewhat longer description',
        visibility: 'for_everyone'
      }
    end

    it 'needs authentication' do
      put :update, params: { id: invisible_element.id, hierarchy_element: update_params }

      expect(response.status).to eq(401)
    end

    it 'returns status 204' do
      request.headers.merge! auth_header(owner)
      put :update, params: { id: invisible_element.id, hierarchy_element: update_params }

      expect(response.status).to eq(204)
    end

    it 'updates the element with the given parameters' do
      request.headers.merge! auth_header(owner)
      put :update, params: { id: invisible_element.id, hierarchy_element: update_params }

      invisible_element.reload
      update_params.each do |key, value|
        expect(invisible_element.send(key)).to eq(value)
      end
    end

    it 'does not allow to update elements for other users' do
      request.headers.merge! auth_header(user)
      put :update, params: { id: public_element.id, hierarchy_element: update_params }

      invisible_element.reload
      update_params.each do |key, value|
        expect(invisible_element.send(key)).not_to eq(value)
      end
      expect(response.status).to eq(401)
    end

    it 'returns a 404 on not visible elements' do
      request.headers.merge! auth_header(user)
      put :update, params: { id: invisible_element.id, hierarchy_element: update_params }

      expect(response.status).to eq(404)
    end

    it 'does allow admins to update elements for other users' do
      request.headers.merge! auth_header(admin)
      put :update, params: { id: invisible_element.id, hierarchy_element: update_params }

      invisible_element.reload
      update_params.each do |key, value|
        expect(invisible_element.send(key)).to eq(value)
      end
      expect(response.status).to eq(204)
    end

    it 'returns a 400 and does not update the element with invalid params' do
      request.headers.merge! auth_header(owner)
      put :update, params: { id: invisible_element.id, hierarchy_element: update_params.merge(name: '') }

      invisible_element.reload
      update_params.each do |key, value|
        expect(invisible_element.send(key)).not_to eq(value)
      end
      expect(response.status).to eq(400)
    end
  end

  describe 'DELETE destroy' do
    before do
      invisible_element
    end

    it 'needs authentication' do
      delete :destroy, params: { id: invisible_element.id }

      expect(response.status).to eq(401)
    end

    it 'returns status 204' do
      request.headers.merge! auth_header(owner)
      delete :destroy, params: { id: invisible_element.id }

      expect(response.status).to eq(204)
    end

    it 'destroys the requested element' do
      request.headers.merge! auth_header(owner)

      expect { delete :destroy, params: { id: invisible_element.id } }.to change(HierarchyElement, :count).by(-1)
    end

    it 'does not allow do destroy elements of other users' do
      request.headers.merge! auth_header(user)

      expect { delete :destroy, params: { id: public_element.id } }.not_to change(HierarchyElement, :count)
      expect(response.status).to eq(401)
    end

    it 'returns a 404 on not vilisble elements' do
      request.headers.merge! auth_header(user)

      expect { delete :destroy, params: { id: invisible_element.id } }.not_to change(HierarchyElement, :count)
      expect(response.status).to eq(404)
    end

    it 'does allow admins do destroy elements of other users' do
      request.headers.merge! auth_header(admin)

      expect { delete :destroy, params: { id: invisible_element.id } }.to change(HierarchyElement, :count).by(-1)
      expect(response.status).to eq(204)
    end
  end
end
