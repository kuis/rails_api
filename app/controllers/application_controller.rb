class ApplicationController < ActionController::Base
  protect_from_forgery

  include DatatablesHelper
  include SentientController

  before_filter :authenticate_user!
  before_filter :set_user_company
  after_filter :update_user_last_activity

  layout :set_layout

  helper_method :current_company


  protected
    def set_layout
      user_signed_in? ? 'application' : 'empty'
    end

    def current_company
      @current_company ||= current_user.companies.first
    end

    def update_user_last_activity
      current_user.update_column(:last_activity_at, DateTime.now) if user_signed_in?
    end

    def set_user_company
      current_user.current_company = current_user.companies.first if user_signed_in?
    end

end
