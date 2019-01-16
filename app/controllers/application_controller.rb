# encoding: UTF-8
# frozen_string_literal: true

require 'base64'

##
# This is the main application controller
# It provides the actions:
# * index
class ApplicationController < ActionController::API
  include Knock::Authenticable

  ##
  # the / in the API
  def index
    pubkey = Base64.encode64(Knock.token_public_key.to_s)
    render json: { IAm: Rails.application.secrets.jwt_issuer, Pubkey: pubkey }
  end

  rescue_from 'AccessGranted::AccessDenied' do
    render json: { IAm: Rails.application.secrets.jwt_issuer, Message: 'Authorization denied. Boop!' }, status: 403
  end
end
