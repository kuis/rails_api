# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  filters          :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#

require 'rails_helper'

RSpec.describe DataExtract::Brand, type: :model do
  describe '#available_columns' do
    let(:subject) { described_class }

    it 'returns the correct columns' do
      expect(subject.exportable_columns).to eql(
       [:name, :marques_list, :created_by, :created_at])
    end
  end

  describe '#rows' do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company,
                         user: create(:user, first_name: 'Benito', last_name: 'Camelas')) }

    let(:campaign) { create(:campaign, name: 'Campaign Absolut FY12', company: company) }
    let(:subject) { described_class.new(company: company, current_user: company_user) }

    it 'returns empty if no rows are found' do
      expect(subject.rows).to be_empty
    end

    describe 'with data' do
      before do
        brand = create(:brand, name: 'Guaro Cacique', company: company, created_by_id: company_user.user.id, created_at: Time.zone.local(2013, 8, 23, 9, 15))
        brand.marques << create(:marque,  name: 'Marque 1')
        brand.marques << create(:marque,  name: 'Marque 2')
        brand.marques << create(:marque,  name: 'Marque 3')
      end

      it 'returns all the events in the company with all the columns' do
        expect(subject.rows).to eql [
          ["Guaro Cacique", "Marque 1, Marque 2, Marque 3", "Benito Camelas", "08/23/2013"]
        ]
      end

      it 'allows to filter the results' do
        subject.filters = { 'active_state' => ['inactive'] }
        expect(subject.rows).to be_empty

        subject.filters = { 'active_state' => ['active'] }
        expect(subject.rows).to eql [
          ["Guaro Cacique", "Marque 1, Marque 2, Marque 3", "Benito Camelas", "08/23/2013"]
        ]
      end

      it 'allows to sort the results' do
        create(:brand, name: 'Cerveza Imperial', company: company, created_by_id: company_user.user.id, created_at: Time.zone.local(2014, 2, 12, 9, 15))
        
        subject.columns = ['name', 'created_at']
        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["Cerveza Imperial", "02/12/2014"], 
          ["Guaro Cacique", "08/23/2013"]
        ]

        subject.default_sort_by = 'name'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Guaro Cacique", "08/23/2013"], 
          ["Cerveza Imperial", "02/12/2014"]
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'ASC'
        expect(subject.rows).to eql [
          ["Cerveza Imperial", "02/12/2014"], 
          ["Guaro Cacique", "08/23/2013"]
        ]

        subject.default_sort_by = 'created_at'
        subject.default_sort_dir = 'DESC'
        expect(subject.rows).to eql [
          ["Guaro Cacique", "08/23/2013"], 
          ["Cerveza Imperial", "02/12/2014"]
        ]
      end
    end
  end
end
