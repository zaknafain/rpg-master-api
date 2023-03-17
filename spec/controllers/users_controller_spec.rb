# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController do
  let(:user)  { FactoryBot.create(:user) }
  let(:owner) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, :admin) }

  describe 'GET index' do
    %i[user owner admin].each do |current|
      describe "as #{current}" do
        it 'returns all users as json' do
          request.headers.merge! auth_header(send(current))
          get :index

          expect(response.status).to eq(200)
          expect(response.body).to of_correct_schema?(
            :user, send(current).id, send(current).admin?
          )
        end
      end
    end

    it 'needs authentication' do
      get :index

      expect(response.status).to eq(401)
    end
  end

  describe 'GET show' do
    %i[user owner admin].each do |current|
      describe "as #{current}" do
        it 'returns the user as json' do
          request.headers.merge! auth_header(send(current))
          get :show, params: { id: owner.id }

          expect(response.status).to eq(200)
          expect(response.body).to of_correct_schema?(
            :user, send(current).id, send(current).admin?
          )
        end
      end
    end

    it 'needs authentication' do
      get :show, params: { id: user.id }

      expect(response.status).to eq(401)
    end
  end

  describe 'GET me' do
    %i[user owner admin].each do |current|
      describe "as #{current}" do
        it 'returns the current user as json' do
          request.headers.merge! auth_header(send(current))
          get :me

          expect(response.status).to eq(200)
          expect(response.body).to of_correct_schema?(
            :user, send(current).id, send(current).admin
          )
        end
      end
    end

    it 'needs authentication' do
      get :me

      expect(response.status).to eq(401)
    end
  end

  describe 'POST sign_in' do
    let(:user) do
      FactoryBot.create(
        :user,
        email: 'foo@bar.com',
        password: 'secret pee',
        password_confirmation: 'secret pee'
      )
    end

    it 'responds successfully' do
      post :sign_in, params: {
        auth: { email: user.email, password: 'secret pee' }
      }

      expect(response.status).to eq(201)
    end

    it 'responds with 400 if the user cannot be found' do
      post :sign_in, params: {
        auth: { email: 'wrong@mail.com', password: 'testtest' }
      }

      expect(response.status).to eq(400)
    end

    it 'responds with 400 if the user provides the wrong password' do
      post :sign_in, params: {
        auth: { email: user.email, password: 'testtest' }
      }

      expect(response.status).to eq(400)
    end

    it 'responds with a jwt' do
      post :sign_in, params: {
        auth: { email: user.email, password: 'secret pee' }
      }

      expect(response.body).to include('jwt')
    end

    it 'responds with a sub that equals the id' do
      post :sign_in, params: {
        auth: { email: user.email, password: 'secret pee' }
      }

      body = response.parsed_body
      jwt = body['jwt']
      decoded_jwt = decoded_token(jwt)

      expect(decoded_jwt[0]).to include('sub' => user.id)
    end

    it 'responds with a user name and id' do
      post :sign_in, params: {
        auth: { email: user.email, password: 'secret pee' }
      }

      body = response.parsed_body
      jwt = body['jwt']
      decoded_jwt = decoded_token(jwt)

      expect(decoded_jwt[0]).to include('name' => user.name)
    end
  end

  describe 'POST create' do
    let(:user_params) do
      { name: 'Created Name', email: 'new.email@created.de', password: 'password', password_confirmation: 'password' }
    end

    it 'creates a user with valid data' do
      post :create, params: { user: user_params }

      expect(response.status).to eq(201)
      expect(User.last&.name).to eq('Created Name')
      expect(User.last&.email).to eq('new.email@created.de')
    end

    it 'returns a 400 and does not create the user with invalid params' do
      expect { post :create, params: { user: user_params.merge(email: '') } }.not_to change(User, :count)

      expect(response.status).to eq(400)
    end

    it 'responds with a jwt token' do
      post :create, params: { user: user_params }

      expect(response.body).to include('jwt')

      body = response.parsed_body
      jwt = body['jwt']
      decoded_jwt = JWT.decode(
        jwt,
        Rails.application.secrets.secret_key_base,
        true,
        algorithm: 'HS256'
      )

      expect(decoded_jwt[0]).to include('name' => 'Created Name')
    end

    it 'does not allow to set the admin flag' do
      post :create, params: { user: user_params.merge(admin: true) }

      new_user = User.last
      expect(new_user.admin).to be_falsey
    end
  end

  describe 'PUT update' do
    it 'needs authentication' do
      put :update, params: { id: owner.id, user: { name: 'New Name' } }

      expect(response.status).to eq(401)
    end

    it 'updates the requested attributes' do
      request.headers.merge! auth_header(owner)

      put :update, params: {
        id: owner.id, user: { name: 'New Name', email: 'new.email@changed.de' }
      }

      expect(response.status).to eq(204)
      expect(owner.reload.name).to eq('New Name')
      expect(owner.email).to eq('new.email@changed.de')
    end

    it 'returns a 400 and does not update the user on invalid params' do
      request.headers.merge! auth_header(owner)

      put :update, params: {
        id: owner.id, user: { name: '', email: 'new.email@changed.de' }
      }

      expect(response.status).to eq(400)
      expect(owner.reload.name).not_to eq('')
      expect(owner.email).not_to eq('new.email@changed.de')
    end

    it 'does not update when the passwords are not the same' do
      request.headers.merge! auth_header(owner)

      put :update, params: {
        id: owner.id, user: {
          password: 'bingo', password_confirmation: 'bongo'
        }
      }

      expect(response.status).to eq(400)
    end

    it 'does not update if wrong user reqested' do
      request.headers.merge! auth_header(user)
      put :update, params: { id: owner.id, user: { name: 'New Name' } }

      expect(response.status).to eq(401)
    end

    it 'does not update the admin flag if not requested by an admin' do
      request.headers.merge! auth_header(user)
      put :update, params: { id: owner.id, user: { admin: true } }

      user.reload
      expect(user.admin).to be_falsey
    end

    it 'updates the user when requested by an admin' do
      request.headers.merge! auth_header(admin)
      put :update, params: { id: owner.id, user: { name: 'New Name' } }

      expect(response.status).to eq(204)
      expect(owner.reload.name).to eq('New Name')
    end
  end

  describe 'DELETE destroy' do
    it 'as normal user it returns forbidden' do
      owner # init
      request.headers.merge! auth_header(user)
      delete :destroy, params: { id: owner.id }

      expect(response.status).to eq(403)
    end

    it 'as owner it returns forbidden' do
      request.headers.merge! auth_header(owner)
      delete :destroy, params: { id: owner.id }

      expect(response.status).to eq(403)
    end

    it 'as admin it returns no content and destroys the user' do
      owner # init
      request.headers.merge! auth_header(admin)

      expect do
        delete :destroy, params: { id: owner.id }
      end.to change(User, :count).by(-1)
      expect(response.status).to eq(204)
    end

    it 'needs authentication' do
      delete :destroy, params: { id: user.id }

      expect(response.status).to eq(401)
    end
  end
end
