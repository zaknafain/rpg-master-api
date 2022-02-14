# frozen_string_literal: true

# Controller for handling the users
class UsersController < ApplicationController
  before_action :authenticate_user!,  except: %i[sign_in create]
  before_action :authenticate_owner,  only: [:update]
  before_action :authenticate_admin!, only: [:destroy]

  def index
    render json: User.all
  end

  def show
    render json: user
  end

  def me
    render json: current_user
  end

  def sign_in
    user_to_sign_in = User.find_by(email: sign_in_params[:email])

    if user_to_sign_in&.authenticate(sign_in_params[:password])
      render json: { jwt: encode_token(user_to_sign_in.to_token_payload) }, status: :created
    else
      head :bad_request
    end
  end

  def create
    new_user = User.create(user_params)

    if new_user.valid?
      render json: { jwt: encode_token(new_user.to_token_payload) }, status: :created
    else
      head :bad_request
    end
  end

  def update
    if user.update(user_params)
      head :no_content
    else
      head :bad_request
    end
  end

  def destroy
    if user.destroy
      head :no_content
    else
      head :bad_request
    end
  end

  private

  def authenticate_owner
    admin_or_owner = current_user.id == user.id || current_user.admin?

    head(:unauthorized) and return unless admin_or_owner
  end

  def user
    @user ||= User.find(params['id'])
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :email, :name, :locale)
  end

  def sign_in_params
    params.require(:auth).permit(:password, :email)
  end
end
