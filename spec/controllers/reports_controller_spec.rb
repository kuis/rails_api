require 'spec_helper'

describe Results::ReportsController do
  let(:report){ FactoryGirl.create(:report, company: @company) }
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end
  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      response.should be_success
      response.should render_template('new')
      response.should render_template('form')
    end
  end

  describe "GET 'show'" do
    it "assigns the loads the correct objects and templates" do
      get 'show', id: report.id
      expect(assigns(:report)).to eql report
      expect(response).to render_template(:show)
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      expect {
        post 'create', report: {name: 'Test report', description: 'Test report description'}, format: :js
      }.to change(Report, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).to_not render_template('_form_dialog')

      report = Report.last
      expect(report.name).to eql 'Test report'
      expect(report.description).to eql 'Test report description'
    end

    it "should render the form_dialog template if errors" do
      expect {
        post 'create', format: :js
      }.to_not change(Report, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      expect(assigns(:report).errors.count).to be > 0
    end
  end



end
