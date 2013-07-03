# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

c = Company.find_or_create_by_name(name: 'Brandscopic')
r = c.roles.find_or_create_by_name(name: 'Admin')
u =  User.create({email: 'admin@brandscopic.com', first_name: 'Admin', last_name: 'Brandscopic', password: 'Adminpass12', password_confirmation: 'Adminpass12', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil}, without_protection: true)
CompanyUser.create({active: true, user_id: u.id, company_id: c.id, role_id: r.id}, without_protection: true)
