# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentTextsController do
  let(:player)               { public_campaign.players.first }
  let(:owner)                { public_campaign.user }
  let(:user)                 { FactoryBot.create(:user) }
  let(:admin)                { FactoryBot.create(:user, :admin) }
  let(:private_campaign)     { FactoryBot.create(:campaign, :with_content, is_public: false) }
  let(:public_campaign)      { FactoryBot.create(:campaign, :with_content, :with_player) }
  let(:public_element)       { public_campaign.hierarchy_elements.find_by(visibility: :for_everyone) }
  let(:player_element)       { public_campaign.hierarchy_elements.find_by(visibility: :for_all_players) }
  let(:invisible_element)    { public_campaign.hierarchy_elements.find_by(visibility: :author_only) }
  let(:pu_public_content)    { public_element.content_texts.find_by(visibility: :for_everyone) }
  let(:pu_player_content)    { public_element.content_texts.find_by(visibility: :for_all_players) }
  let(:pu_invisible_content) { public_element.content_texts.find_by(visibility: :author_only) }
  let(:pl_public_content)    { player_element.content_texts.find_by(visibility: :for_everyone) }
  let(:pl_player_content)    { player_element.content_texts.find_by(visibility: :for_all_players) }
  let(:pl_invisible_content) { player_element.content_texts.find_by(visibility: :author_only) }
  let(:in_public_content)    { invisible_element.content_texts.find_by(visibility: :for_everyone) }
  let(:in_player_content)    { invisible_element.content_texts.find_by(visibility: :for_all_players) }
  let(:in_invisible_content) { invisible_element.content_texts.find_by(visibility: :author_only) }

  describe 'GET index' do
    it 'returns status 200 and the correct schema' do
      get :index, params: { hierarchy_element_id: public_element.id }

      expect(response.status).to eq(200)
      expect(response.body).to of_correct_schema?(:content_text, nil, false)
    end

    it 'returns all content texts which are for everyone if not signed in' do
      get :index, params: { hierarchy_element_id: public_element.id }

      expect(response.body).to     include(pu_public_content.id.to_s)
      expect(response.body).not_to include(pu_player_content.id.to_s)
      expect(response.body).not_to include(pu_invisible_content.id.to_s)
    end

    it 'returns all content texts which are for everyone if requested as registered user' do
      request.headers.merge! auth_header(user)
      get :index, params: { hierarchy_element_id: public_element.id }

      expect(response.body).to     include(pu_public_content.id.to_s)
      expect(response.body).not_to include(pu_player_content.id.to_s)
      expect(response.body).not_to include(pu_invisible_content.id.to_s)
    end

    it 'returns content for players if requested as player' do
      request.headers.merge! auth_header(player)
      get :index, params: { hierarchy_element_id: public_element.id }

      expect(response.body).to     include(pu_public_content.id.to_s)
      expect(response.body).to     include(pu_player_content.id.to_s)
      expect(response.body).not_to include(pu_invisible_content.id.to_s)
    end

    it 'returns all content for owners' do
      request.headers.merge! auth_header(owner)
      get :index, params: { hierarchy_element_id: public_element.id }

      expect(response.body).to include(pu_public_content.id.to_s)
      expect(response.body).to include(pu_player_content.id.to_s)
      expect(response.body).to include(pu_invisible_content.id.to_s)
    end

    it 'returns all elements for admins' do
      request.headers.merge! auth_header(admin)
      get :index, params: { hierarchy_element_id: public_element.id }

      expect(response.body).to include(pu_public_content.id.to_s)
      expect(response.body).to include(pu_player_content.id.to_s)
      expect(response.body).to include(pu_invisible_content.id.to_s)
    end

    it 'returns a 404 if the hierarchy element is not existing' do
      public_campaign
      element_id = HierarchyElement.last.id

      get :index, params: { hierarchy_element_id: element_id + 1 }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the hierarchy element is not visible to the user' do
      get :index, params: { hierarchy_element_id: invisible_element.id }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the campaign is not visible to the user' do
      element_id = private_campaign.hierarchy_elements.find_by(visibility: :for_everyone).id
      get :index, params: { hierarchy_element_id: element_id }

      expect(response.status).to eq(404)
    end
  end

  describe 'POST create' do
    let(:create_params) do
      {
        content: 'Created Content',
        visibility: 'author_only',
        ordering: 99
      }
    end
    let(:params) { { hierarchy_element_id: public_element.id, content_text: create_params } }

    it 'needs authentication' do
      post :create, params: params

      expect(response.status).to eq(401)
    end

    it 'returns status 201 and the created content' do
      request.headers.merge! auth_header(owner)
      post :create, params: params

      expect(response.status).to eq(201)
      expect(response.body).to of_correct_schema?(:content_text, owner.id, owner.admin?)
    end

    it 'creates new content' do
      request.headers.merge! auth_header(owner)

      expect { post :create, params: params }.to change(ContentText, :count).by(1)

      content = public_element.content_texts.order(created_at: :asc).last
      create_params.each do |key, value|
        expect(content.send(key)).to eq(value)
      end
    end

    it 'returns a 404 if the element id is not existing' do
      request.headers.merge! auth_header(owner)
      element_id = HierarchyElement.last.id
      post :create, params: { content_text: create_params, hierarchy_element_id: element_id + 1 }

      expect(response.status).to eq(404)
    end

    it 'returns a 404 if the campaign is not visible to the user' do
      request.headers.merge! auth_header(owner)
      element_id = private_campaign.hierarchy_elements.find_by(visibility: :for_everyone).id
      post :create, params: { content_text: create_params, hierarchy_element_id: element_id }

      expect(response.status).to eq(404)
    end
  end

  describe 'PUT update' do
    let(:update_params) do
      {
        content: 'Updated Content',
        visibility: 'for_everyone',
        ordering: 69
      }
    end

    it 'needs authentication' do
      put :update, params: { id: pu_invisible_content.id, content_text: update_params }

      expect(response.status).to eq(401)
    end

    it 'returns status 204' do
      request.headers.merge! auth_header(owner)
      put :update, params: { id: pu_invisible_content.id, content_text: update_params }

      expect(response.status).to eq(204)
    end

    it 'updates the content with the given parameters' do
      request.headers.merge! auth_header(owner)
      put :update, params: { id: pu_invisible_content.id, content_text: update_params }

      pu_invisible_content.reload
      update_params.each do |key, value|
        expect(pu_invisible_content.send(key)).to eq(value)
      end
    end

    it 'does not allow to update content for other users' do
      request.headers.merge! auth_header(user)
      put :update, params: { id: pu_invisible_content.id, content_text: update_params }

      pu_invisible_content.reload
      update_params.each do |key, value|
        expect(pu_invisible_content.send(key)).not_to eq(value)
      end
      expect(response.status).to eq(404)
    end

    it 'does allow admins to update contents for other users' do
      request.headers.merge! auth_header(admin)
      put :update, params: { id: pu_invisible_content.id, content_text: update_params }

      pu_invisible_content.reload
      update_params.each do |key, value|
        expect(pu_invisible_content.send(key)).to eq(value)
      end
      expect(response.status).to eq(204)
    end
  end

  describe 'DELETE destroy' do
    before do
      pu_invisible_content
    end

    it 'needs authentication' do
      delete :destroy, params: { id: pu_invisible_content.id }

      expect(response.status).to eq(401)
    end

    it 'returns status 204' do
      request.headers.merge! auth_header(owner)
      delete :destroy, params: { id: pu_invisible_content.id }

      expect(response.status).to eq(204)
    end

    it 'destroys the requested content' do
      request.headers.merge! auth_header(owner)

      expect { delete :destroy, params: { id: pu_invisible_content.id } }.to change(ContentText, :count).by(-1)
    end

    it 'does not allow do destroy contents of other users' do
      request.headers.merge! auth_header(user)

      expect { delete :destroy, params: { id: pu_invisible_content.id } }.not_to change(ContentText, :count)
      expect(response.status).to eq(404)
    end

    it 'does allow admins do destroy contents of other users' do
      request.headers.merge! auth_header(admin)

      expect { delete :destroy, params: { id: pu_invisible_content.id } }.to change(ContentText, :count).by(-1)
      expect(response.status).to eq(204)
    end
  end
end