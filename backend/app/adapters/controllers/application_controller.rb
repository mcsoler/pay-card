# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'json'
require_relative '../../infrastructure/jwt/jwt_service'
require_relative '../../domain/errors'

class ApplicationController < Sinatra::Base
  configure do
    set :show_exceptions, false
    set :raise_errors,    false
  end

  before do
    content_type :json
  end

  # ── Dependency injection helpers ─────────────────────────────────────────
  class << self
    def jwt_service
      @jwt_service ||= Infrastructure::Jwt::JwtService.new
    end
  end

  # ── Auth helper ───────────────────────────────────────────────────────────
  def authenticate!
    token   = extract_bearer_token
    payload = self.class.jwt_service.decode(token)
    halt 401, json(error: 'Unauthorized') if payload.nil?

    @current_customer_id = payload['customer_id']
  end

  def current_customer_id
    @current_customer_id
  end

  # ── JSON helpers ──────────────────────────────────────────────────────────
  def parsed_body
    @parsed_body ||= begin
      request.body.rewind
      JSON.parse(request.body.read, symbolize_names: true)
    rescue JSON::ParserError
      {}
    end
  end

  def success(data, status: 200)
    halt status, json(data: data)
  end

  def failure(message, status: 400)
    halt status, json(error: message)
  end

  def validation_error(errors)
    halt 422, json(errors: errors)
  end

  # ── Error handlers ────────────────────────────────────────────────────────
  error Domain::Errors::NotFoundError do
    halt 404, json(error: env['sinatra.error'].message)
  end

  error StandardError do
    halt 500, json(error: 'Internal server error')
  end

  private

  def extract_bearer_token
    header = env['HTTP_AUTHORIZATION'] || ''
    header.start_with?('Bearer ') ? header.sub('Bearer ', '') : nil
  end
end
