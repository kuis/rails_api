class Api::V1::ApiController < ActionController::Base
  respond_to :json, :xml

  include SentientController

  rescue_from 'Api::V1::InvalidAuthToken', with: :invalid_token
  rescue_from 'Api::V1::InvalidCompany', with: :invalid_company
  rescue_from 'ActiveRecord::RecordNotFound', with: :record_not_found

  before_action :ensure_valid_request
  after_action :set_access_control_headers
  after_action :update_user_last_activity_mobile

  before_action :set_user

  load_and_authorize_resource only: [:show, :edit, :update, :destroy], unless: :skip_default_validation
  authorize_resource only: [:create, :index], unless: :skip_default_validation

  check_authorization

  def options
  end

  protected

  def current_company
    @current_company ||= current_company_user.company
  end

  def current_company_user
    @current_company_user ||= current_user.company_users.where(company_id: current_company_id).first if current_user.present?
    fail Api::V1::InvalidCompany.new(current_company_id) if @current_company_user.nil? || !@current_company_user.active?

    @current_company_user
  end

  def current_user
    token = request.headers['X-Auth-Token']
    email = request.headers['X-User-Email']
    return if token.nil? || token.strip == ''
    @current_user ||= User.where(email: email).find_by_authentication_token(token) or fail Api::V1::InvalidAuthToken.new(token), 'invalid token'
  end

  def current_company_id
    request.headers['X-Company-Id']
  end

  def invalid_token
    respond_to do |format|
      format.json do
        render status: 401,
               json: { success: false,
                       info: 'Invalid auth token',
                       data: {} }
      end
      format.xml do
        render status: 401,
               xml: { success: false,
                      info: 'Invalid auth token',
                      data: {} }.to_xml(root: 'response')
      end
    end
  end

  def invalid_company
    respond_to do |format|
      format.json do
        render status: 401,
               json: { success: false,
                       info: 'Invalid company',
                       data: {} }
      end
      format.xml do
        render status: 401,
               xml: { success: false,
                      info: 'Invalid company',
                      data: {} }.to_xml(root: 'response')
      end
    end
  end

  def record_not_found
    respond_to do |format|
      format.json do
        render status: 404,
               json: { success: false,
                       info: 'Record not found',
                       data: {} }
      end
      format.xml do
        render status: 404,
               xml: { success: false,
                      info: 'Record not found',
                      data: {} }.to_xml(root: 'response')
      end
    end
  end

  def set_user
    User.current = current_user
    User.current.current_company = current_company if current_company_id
  end

  def set_access_control_headers
    if ENV['HEROKU_APP_NAME'] == 'brandscopic'
      headers['Access-Control-Allow-Origin'] = 'http://m.brandscopic.com'
    else
      headers['Access-Control-Allow-Origin'] = '*'
    end
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Expose-Headers'] = 'ETag'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type,If-Modified-Since,If-None-Match,X-Auth-Token,X-User-Email,X-Company-Id'
    headers['Access-Control-Max-Age'] = '86400'
  end

  def update_user_last_activity_mobile
    @current_company_user.update_column(:last_activity_mobile_at, DateTime.now) if user_signed_in? && @current_company_user.present?
  end

  def ensure_valid_request
    return if %w(json xml).include?(params[:format]) || request.headers['Accept'] =~ /json|xml/
    render nothing: true, status: 406
  end

  def skip_default_validation
    false
  end
end

class Api::V1::InvalidAuthToken < StandardError
  attr_reader :token

  def initialize(token)
    @token = token
  end
end

class Api::V1::InvalidCompany < StandardError
  attr_reader :id

  def initialize(id)
    @id = id
  end
end
