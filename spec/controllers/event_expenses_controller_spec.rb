require 'spec_helper'

describe EventExpensesController do
  let(:event){ FactoryGirl.create(:event, company: @company) }
  let(:event_expense){ FactoryGirl.create(:event_expense, event: event) }

  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', event_id: event.to_param, id: event_expense.id, format: :js
      response.should be_success
    end

    it 'cannot edit an event expense on other company' do
      other_event = FactoryGirl.create(:event, company: FactoryGirl.create(:company))
      other_expense = FactoryGirl.create(:event_expense, event: other_event)
      expect {
        get 'edit', event_id: other_event.to_param, id: other_expense.id, format: :js
      }.to raise_exception(CanCan::AccessDenied)
    end
  end
end
