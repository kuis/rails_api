class BrandsController < FilteredController
  actions :index, :new, :create
  belongs_to :campaign, :brand_portfolio, optional: true
  respond_to :json, only: [:index]
  respond_to :js, only: [:new, :create]

  has_scope :with_text
  has_scope :not_in_portfolio

  def create
    create! do |success, failure|
      success.js do
          parent.brands << resource if parent? and parent
          render :create
      end
    end
  end

  private

    def collection_to_json
      collection.map{|brand| {
        :id => brand.id,
        :name => brand.name,
        :links => {
            delete: (parent? ? delete_brand_brand_portfolio_url(parent, brand) : nil)
        }
      }}
    end

    def sort_options
      {
        'name' => { :order => 'brands.name' }
      }
    end
end
