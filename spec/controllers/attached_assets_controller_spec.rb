require 'spec_helper'

describe AttachedAssetsController, search: true  do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "PUT 'update'" do
    let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) }
    let(:attached_asset){ FactoryGirl.create(:attached_asset, attachable: event) }
    it "must update the rating attribute" do
      put 'update', id: attached_asset.to_param, rating: 2
      response.should be_success
    end
  end

end