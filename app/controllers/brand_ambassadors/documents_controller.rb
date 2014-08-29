class BrandAmbassadors::DocumentsController < ::DocumentsController
  respond_to :js, only: [:create, :new]

  belongs_to :visit, polymorphic: true, optional: true

  defaults :resource_class => ::BrandAmbassadors::Document

  include DeactivableHelper

  load_and_authorize_resource

  skip_load_and_authorize_resource only: [:create, :new]
  before_action :authorize_create, only: [:create, :new]

  protected
    def build_resource_params
      [(permitted_params || {}).merge(asset_type: 'ba_document')]
    end

    def permitted_params
      params.permit(attached_asset: [:direct_upload_url])[:attached_asset]
    end

    def authorize_create
      authorize! :create, BrandAmbassadors::Document
    end
end
