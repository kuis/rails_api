require 'rails_helper'
require 'sunspot_test/rspec'

describe VenuesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }

  describe "GET 'show'" do
    before do
      Kpi.create_global_kpis
    end

    let(:venue) { create(:venue, company: company, place: create(:place, is_custom_place: true, reference: nil)) }

    it 'returns http success' do
      get 'show', id: venue.to_param
      expect(response).to be_success
    end

    describe 'when accessed with Google Places params' do
      it 'create a venue and redirects the user to it' do
        place = create(:place, place_id: '24d9cbaf29793a503e9', reference: 'CnRvAAAAjP74ZS9G')
        expect do
          get 'show', id: '24d9cbaf29793a503e9', ref: 'CnRvAAAAjP74ZS9G'
        end.to change(Venue, :count).by(1)
        venue = Venue.last
        expect(venue.place).to eql place
        expect(response).to redirect_to(venue_path(venue))
      end

      describe 'when user is not authenticated' do
        let(:user) { nil }

        it 'redirects the user to the login page' do
          place = create(:place, place_id: '24d9cbaf29793a503e9', reference: 'CnRvAAAAjP74ZS9G')
          expect do
            get 'show', id: '24d9cbaf29793a503e9', ref: 'CnRvAAAAjP74ZS9G'
          end.to_not change(Venue, :count)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe "GET 'select_areas'" do
    let(:venue) { create(:venue, company: company, place: create(:place, is_custom_place: true, reference: nil)) }

    it 'returns http success' do
      area = create(:area, company: company)

      # Another area already in venue
      assigned_area = create(:area, company: company)

      venue.place.areas << assigned_area
      xhr :get, 'select_areas', id: venue.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template('select_areas')

      expect(assigns(:areas)).to eq([area])
    end
  end

  describe 'POST #add_areas' do
    let(:venue) { create(:venue, company: company, place: create(:place, is_custom_place: true, reference: nil)) }

    it 'adds the area to the place' do
      area = create(:area, company: company)
      expect do
        xhr :post, 'add_areas', id: venue.to_param, area_id: area.to_param, format: :js
      end.to change(venue.place.areas, :count).by(1)
    end
  end

  describe 'DELETE #delete_area' do
    let(:venue) { create(:venue, company: company, place: create(:place, is_custom_place: true, reference: nil)) }

    it 'adds the area to the place' do
      area = create(:area, company: company)
      venue.place.areas << area
      expect do
        delete 'delete_area', id: venue.to_param, area_id: area.to_param, format: :js
      end.to change(venue.place.areas, :count).by(-1)
    end
  end

  describe "GET 'index'" do
    it 'queue the job for export the list' do
      expect do
        xhr :get, :index, format: :xls
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
    end
  end

end
