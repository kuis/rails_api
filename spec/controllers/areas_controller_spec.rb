require 'spec_helper'

describe AreasController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  let(:area){ FactoryGirl.create(:area, company: @company) }

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: area.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'items'" do
    it "returns http success" do
      get 'items'
      response.should be_success
    end
  end

  describe "GET 'show'" do
    it "assigns the loads the correct objects and templates" do
      get 'show', id: area.id
      assigns(:area).should == area
      response.should render_template(:show)
    end
  end

  describe "POST 'create'" do
    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', area: {name: 'Test Area', description: 'Test Area description'}, format: :js
      }.should change(Area, :count).by(1)
      area = Area.last
      area.name.should == 'Test Area'
      area.description.should == 'Test Area description'
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Area, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:area).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    it "deactivates an active area" do
      area.update_attribute(:active, true)
      get 'deactivate', id: area.to_param, format: :js
      response.should be_success
      area.reload.active?.should be_falsey
    end

    it "activates an inactive area" do
      area.update_attribute(:active, false)
      get 'activate', id: area.to_param, format: :js
      response.should be_success
      area.reload.active?.should be_truthy
    end
  end

  describe "PUT 'update'" do
    it "must update the area attributes" do
      t = FactoryGirl.create(:area)
      put 'update', id: area.to_param, area: {name: 'Test Area', description: 'Test Area description'}
      assigns(:area).should == area
      response.should redirect_to(area_path(area))
      area.reload
      area.name.should == 'Test Area'
      area.description.should == 'Test Area description'
    end
  end

end