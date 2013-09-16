# == Schema Information
#
# Table name: kpis
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  kpi_type          :string(255)
#  capture_mechanism :string(255)
#  company_id        :integer
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  module            :string(255)      default("custom"), not null
#

require 'spec_helper'

describe Kpi do
  it { should belong_to(:company) }
  it { should have_many(:kpis_segments) }
  it { should have_many(:goals) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:description) }
  it { should allow_mass_assignment_of(:kpi_type) }
  it { should allow_mass_assignment_of(:capture_mechanism) }
  it { should allow_mass_assignment_of(:kpis_segments_attributes) }
  it { should allow_mass_assignment_of(:goals_attributes) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:company_id) }
  it { should_not allow_mass_assignment_of(:created_by_id) }
  it { should_not allow_mass_assignment_of(:updated_by_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }
  it { should_not allow_mass_assignment_of(:module) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).scoped_to(:company_id) }
  it { should validate_numericality_of(:company_id) }

  # TODO: reject_if needs to be tested in the following line
  it { should accept_nested_attributes_for(:kpis_segments) }
  it { should accept_nested_attributes_for(:goals) }
end
