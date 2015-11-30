# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

require 'rails_helper'

RSpec.describe DataExtract::Invite, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql([
        %w(campaign_name Campaign), ['end_date', 'End Date'],
        ['end_time', 'End Time'], ['start_date', 'Start Date'], ['start_time', 'Start Time'],
        ['event_status', 'Event Status'], ['place_name', 'Venue Name'], ['place_street', 'Venue Street'], ['place_city', 'Venue City'],
        ['place_state', 'Venue State'], ['place_zipcode', 'Venue ZIP Code'],
        %w(rsvps RSVPs), %w(attendees Attendees), %w(invitees Invites),
        ['created_at', 'Created At'], ['created_by', 'Created By'], ['modified_at', 'Modified At'],
        ['modified_by', 'Modified By'], ["active_state", "Active State"]])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }
    let(:place) { create(:place, name: 'Place 2') }
    let(:company_user) do
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Benito', last_name: 'Camelas'))
    end
    let(:event) do
      create(:event, company: company, campaign: campaign, place: place,
                     start_date: '01/01/2014', end_date: '01/01/2014')
    end
    let(:subject) { described_class.new(company: company, current_user: company_user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      let!(:invite) do
        create :invite, rsvps_count: 15, attendees: 3, invitees: 5,
                        event: event,
                        created_at: Time.zone.local(2013, 8, 22, 11, 59)
      end

      it 'returns all the invites in the company with all the columns' do
        subject.columns = %w(invitees attendees rsvps created_by created_at campaign_name end_date end_time start_date start_time event_status place_street place_city place_name place_state place_zipcode active_state)
        expect(subject.rows).to eql [
          [5, 3, 15, nil, '08/22/2013', 'Test Campaign FY01', '01/01/2014',
           '08:00 PM', '01/01/2014', '06:00 PM', 'Unsent', '11 Main St.',
           'New York City', 'Place 2', 'NY', '12345', 'Active']
        ]
      end

      it 'allows to sort the results' do
        other_campaign = create(:campaign, company: company, name: 'Campaign FY15')
        other_event = create(:approved_event, company: company, campaign: other_campaign, place: place)
        create :invite, invitees: 1, event: event,
                        created_at: Time.zone.local(2013, 8, 21, 11, 59)
        create :invite, invitees: 10, event: other_event,
                        created_at: Time.zone.local(2013, 8, 23, 11, 59)

        subject.columns = %w(invitees created_at campaign_name)
        subject.default_sort_by = 'invitees'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          [1,  '08/21/2013', 'Test Campaign FY01'],
          [5, '08/22/2013', 'Test Campaign FY01'],
          [10, '08/23/2013', 'Campaign FY15']
        ]

        subject.default_sort_by = 'invitees'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          [10, '08/23/2013', 'Campaign FY15'],
          [5, '08/22/2013', 'Test Campaign FY01'],
          [1,  '08/21/2013', 'Test Campaign FY01']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          [1,  '08/21/2013', 'Test Campaign FY01'],
          [5, '08/22/2013', 'Test Campaign FY01'],
          [10, '08/23/2013', 'Campaign FY15']
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          [10, '08/23/2013', 'Campaign FY15'],
          [5, '08/22/2013', 'Test Campaign FY01'],
          [1,  '08/21/2013', 'Test Campaign FY01']
        ]
      end
    end
  end
end
