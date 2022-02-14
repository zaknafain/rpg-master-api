# frozen_string_literal: true

require 'jwt'

# Abstract Controller every other controller inherits from
class ApplicationController < ActionController::API
  rescue_from ActionController::ParameterMissing, with: :head_bad_request
  rescue_from ActiveRecord::RecordNotFound, with: :head_not_found

  def encode_token(payload)
    JWT.encode(payload, jwt_secret, 'HS256')
  end

  def authenticate_user!
    return if current_user

    head :unauthorized and return
  end

  def authenticate_admin!
    return if current_user&.admin?

    head :forbidden and return
  end

  def current_user
    return @current_user if @current_user
    return unless decoded_token

    user_id       = decoded_token[0]['sub']
    @current_user = User.find_by(id: user_id)
  end

  def decoded_token
    return unless bearer_jwt_token

    JWT.decode(bearer_jwt_token, jwt_secret, true, algorithm: 'HS256')
  rescue JWT::DecodeError
    nil
  end

  def bearer_jwt_token
    return unless auth_header

    # auth_header: 'Bearer <token>'
    auth_header.split[1]
  end

  def auth_header
    request.headers['Authorization']
  end

  def head_bad_request
    head :bad_request and return
  end

  def head_not_found
    head :not_found and return
  end

  def jwt_secret
    Rails.application.secrets.secret_key_base
  end
end
