# == Schema Information
#
# Table name: brands
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Brand < ActiveRecord::Base
  track_who_does_it

  attr_accessible :name, :campaigns_ids

  validates :name, presence: true, uniqueness: true

  # Campaigns-Brands relationship
  has_and_belongs_to_many :campaigns

  has_many :brand_portfolios_brands
  has_many :brand_portfolios, through: :brand_portfolios_brands

  scope :with_text, lambda{|text| where('brands.name ilike ? ', "%#{text}%") }

  scope :not_in_portfolio, lambda{|portfolio| where("brands.id not in (#{BrandPortfoliosBrand.select('brand_id').scoped_by_brand_portfolio_id(portfolio).to_sql})") }

  searchable do
    text :name_txt do
      name
    end

    string :name
  end
end
