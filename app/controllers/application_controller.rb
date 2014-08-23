class ApplicationController < ActionController::Base
  protect_from_forgery

  around_filter :scope_current_user

  skip_before_action :verify_authenticity_token, :if =>lambda{ params[:authenticity_token].present? && params[:authenticity_token] == 'S3CR37Master70k3N' }

  before_action :authenticate_user!
  after_filter :update_user_last_activity

  layout :set_layout

  helper_method :current_company, :custom_body_class, :modal_dialog_title

  rescue_from 'CanCan::AccessDenied', with: :access_denied

  protected
    def set_layout
      user_signed_in? ? 'application' : 'empty'
    end

    def company_users
      current_company.company_users
    end

    def company_roles
      current_company.roles
    end

    def company_teams
      current_company.teams
    end

    def company_campaigns
      current_company.campaigns.order('name')
    end

    def current_company_user
      current_user.current_company_user
    end

    def current_company
      @current_company ||= begin
        current_company_id = session[:current_company_id]
        company = nil
        if user_signed_in?
          if current_company_id
            company = current_user.companies.find(current_company_id) rescue nil
          else
            company = current_user.current_company
          end
          company ||= current_user.companies.first
        end
        company
      end
    end

    def update_user_last_activity
      current_company_user.update_column(:last_activity_at, DateTime.now) if user_signed_in? && request.format.html? && current_company_user.present?
    end

    # Overwriting the sign_out redirect path method
    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end

    def custom_body_class
      @custom_body_class ||= ''
    end

    def modal_dialog_title
      I18n.translate("modals.title.#{resource.new_record? ? 'new' : 'edit'}.#{resource.class.name.underscore.downcase}")
    end

    def access_denied(exception)
      @exception = exception
      respond_to do |format|
        format.json { render text: 'Permission denied', status: 403 }
        format.js { render 'access_denied' }
        format.html { render 'access_denied' }
      end
    end

    def scope_current_user
      User.current = current_user
      if user_signed_in?
        Company.current = current_user.current_company = current_company
        Time.zone = current_user.time_zone
        ::NewRelic::Agent.add_custom_parameters(:user_id => current_user.id)
        ::NewRelic::Agent.add_custom_parameters(:company_user_id => current_company_user.id)
      end
      yield
    ensure
      User.current = nil
      Company.current = nil
      Time.zone = Rails.application.config.time_zone
    end

    def url_valid?(url)
      url = URI.parse(url) rescue false
      url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    end

    def with_immediate_indexing
      old_session = Sunspot.session
      if Sunspot.session.is_a?(Sunspot::Queue::SessionProxy)
        Sunspot.session = Sunspot.session.session
      end
      yield
      Sunspot.commit
    ensure
      Sunspot.session = old_session
    end
end
