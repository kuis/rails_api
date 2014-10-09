require 'rails_helper'

describe Results::ActivitiesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }  # login user

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'returns http success on html format' do
      get 'items'
      expect(response).to be_success
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

  describe "GET 'list_export'", search: true do
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    let(:place) do
      create(:place, name: 'Bar Prueba', city: 'Los Angeles',
                     state: 'California', country: 'US', td_linx_code: '443321')
    end
    let(:event) { create(:event, campaign: campaign, place: place) }
    let(:activity_type) { create(:activity_type, name: 'My Activity Type', campaign_ids: [campaign.id], company: company) }
    let(:event_activity) do
      create(:activity, activitable: event, activity_date: '01/01/2014',
        activity_type: activity_type, company_user: company_user)
    end

    it 'return an empty book with the correct headers' do
      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
         'ADDRESS', 'CITY', 'STATE', 'ZIP']
      ])
    end

    it 'should include the event data results' do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      area = create(:area, name: 'My area', company: company)
      area.places << create(:city, name: 'Los Angeles', state: 'California', country: 'US')
      campaign.areas << area

      field = create(:form_field_number, name: 'My Numeric Field', fieldable: activity_type)

      event_activity.results_for([field]).first.value = 123
      event_activity.save

      Sunspot.commit

      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      ResqueSpec.perform_all(:export)

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
         'ADDRESS', 'CITY', 'STATE', 'ZIP', 'MY NUMERIC FIELD'],
        ['Test Campaign FY01', user.full_name, "2014-01-01T00:00", "My Activity Type", 'My area',
         '443321', 'Bar Prueba', 'Bar Prueba, Los Angeles, California, 12345', 'Los Angeles',
         'California', '12345', '123.0']
      ])
    end

    describe "custom fields" do
      before do
        create(:form_field_checkbox,
               name: 'My Chk Field', fieldable: activity_type, options: [
                 create(:form_field_option, name: 'Chk Opt1'),
                 create(:form_field_option, name: 'Chk Opt2')])

        other_campaign = create(:campaign, company: company, name: 'Other Campaign FY01')
        other_activity_type = create(:activity_type, company: company, campaign_ids: [other_campaign.id])
        create(:form_field_radio,
               name: 'My Radio Field', fieldable: other_activity_type, options: [
                 create(:form_field_option, name: 'Radio Opt1'),
                 create(:form_field_option, name: 'Radio Opt2')])
      end
      it 'should include the activity data results only for the given campaign' do
        expect { xhr :get, 'index', campaign: [campaign.id], format: :xls }.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        expect(export.reload).to have_rows([
          ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
            'ADDRESS', 'CITY', 'STATE', 'ZIP', 'MY CHK FIELD']
        ])
      end

      it 'should include any custom kpis from all the campaigns' do
        expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        expect(export.reload).to have_rows([
          ['CAMPAIGN NAME', 'USER', 'DATE', 'ACTIVITY TYPE', 'AREAS', 'TD LINX CODE', 'VENUE NAME',
           'ADDRESS', 'CITY', 'STATE', 'ZIP', 'MY CHK FIELD', 'MY RADIO FIELD']
        ])
      end
    end
  end
end
