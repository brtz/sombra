# encoding: UTF-8
# frozen_string_literal: true

##
# This is the main application controller
# It provides the actions:
# * index
class ApplicationController < ActionController::API
  include Knock::Authenticable

  ##
  # the / in the API
  def index
    render json: { IAm: Rails.application.secrets.jwt_issuer, Pubkey: Knock.token_public_key.to_pem }
  end

  rescue_from 'AccessGranted::AccessDenied' do
    render json: { IAm: Rails.application.secrets.jwt_issuer, Message: 'Authorization denied. Boop!' }, status: 403
  end
end
