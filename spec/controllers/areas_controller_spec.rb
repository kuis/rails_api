require 'rails_helper'

describe AreasController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  let(:area) { create(:area, company: @company) }

  describe "GET 'edit'" do
    it 'returns http success' do
      xhr :get, 'edit', id: area.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end

    it 'queue the job for export the list to XLS' do
      expect do
        xhr :get, :index, format: :xls
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('AreasController')
      expect(export.export_format).to eql('xls')
    end

    it 'queue the job for export the list to PDF' do
      expect do
        xhr :get, :index, format: :pdf
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('AreasController')
      expect(export.export_format).to eql('pdf')
    end
  end

  describe "GET 'items'" do
    it 'returns http success' do
      get 'items'
      expect(response).to be_success
    end
  end

  describe "GET 'cities'" do
    it 'assigns the loads the correct objects and templates' do
      expect_any_instance_of(Area).to receive(:cities).and_return([double(name: 'My Cool City')])
      get 'cities', id: area.id, format: :json
      expect(assigns(:area)).to eq(area)
      cities = JSON.parse(response.body)
      expect(cities).to eql ['My Cool City']
    end
  end

  describe "GET 'show'" do
    it 'assigns the loads the correct objects and templates' do
      get 'show', id: area.id
      expect(assigns(:area)).to eq(area)
      expect(response).to render_template(:show)
    end
  end

  describe "POST 'create'" do
    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', area: { name: 'Test Area', description: 'Test Area description' }, format: :js
      end.to change(Area, :count).by(1)
      area = Area.last
      expect(area.name).to eq('Test Area')
      expect(area.description).to eq('Test Area description')
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(Area, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:area).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    it 'deactivates an active area' do
      area.update_attribute(:active, true)
      xhr :get, 'deactivate', id: area.to_param, format: :js
      expect(response).to be_success
      expect(area.reload.active?).to be_falsey
    end

    it 'activates an inactive area' do
      area.update_attribute(:active, false)
      xhr :get, 'activate', id: area.to_param, format: :js
      expect(response).to be_success
      expect(area.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    it 'must update the area attributes' do
      t = create(:area)
      put 'update', id: area.to_param, area: { name: 'Test Area', description: 'Test Area description' }
      expect(assigns(:area)).to eq(area)
      expect(response).to redirect_to(area_path(area))
      area.reload
      expect(area.name).to eq('Test Area')
      expect(area.description).to eq('Test Area description')
    end
  end

  describe "GET 'list_export'", search: true do
    it 'should return an empty book with the correct headers' do
      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION']
      ])
    end

    it 'should include the results' do
      create(:area, name: 'Gran Area Metropolitana', description: 'Ciudades principales de Costa Rica',
              active: true, company: @company)
      Sunspot.commit

      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      expect(ListExportWorker).to have_queued(ListExport.last.id)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION'],
        ['Gran Area Metropolitana', 'Ciudades principales de Costa Rica']
      ])
    end
  end
end
