require 'spec_helper'

describe ApplicationHelper do
  describe "#place_address" do
    it "should add the name to the address" do
      place= double(Place, {name: 'Some Place Name', street: nil, state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name</address>", helper.place_address(place)
    end

    it "should add the street to the address" do
      place= double(Place, {name: 'Some Place Name', street: 'Street Name', state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name<br/>Street Name</address>", helper.place_address(place)
    end

    it "should not add the street to the address if it's the same as the place name" do
      place= double(Place, {name: 'Some Place Name', street: 'Some Place Name', state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name</address>", helper.place_address(place)
    end

    it "should not add the street if it has an empty string or with spaces" do
      place= double(Place, {name: 'Some Place Name', street: ' ', state: nil, zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>Some Place Name</address>", helper.place_address(place)
    end

    it "should add the city to the address" do
      place= double(Place, {name: nil, street: nil, state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil})
      assert_dom_equal "<address>Curridabat</address>", helper.place_address(place)
    end

    it "should add the name and city to the address is separated lines" do
      place= double(Place, {name: 'Place name', street: nil, state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil})
      assert_dom_equal "<address>Place name<br />Curridabat</address>", helper.place_address(place)
    end

    it "should add the name, street and city to the address is separated lines" do
      place= double(Place, {name: 'Place name', street: '123 uno dos tres', state: nil, zipcode: nil, city: 'Curridabat', formatted_address: nil})
      assert_dom_equal "<address>Place name<br />123 uno dos tres<br />Curridabat</address>", helper.place_address(place)
    end

    pending "should add the state to the address" do
      place= double(Place, {name: nil, street: nil, state: 'California', zipcode: nil, city: nil, formatted_address: nil})
      assert_dom_equal "<address>California</address>", helper.place_address(place)
    end

    pending "should add the state and the zipcode to the address separated by a commma" do
      place= double(Place, {name: nil, street: nil, state: 'California', zipcode: '90210', city: nil, formatted_address: nil})
      assert_dom_equal "<address>California, 90210</address>", helper.place_address(place)
    end

    it "should add the city, state and the zipcode to the address separated by a commma" do
      place= double(Place, {name: nil, street: nil, state: 'California', zipcode: '90210', city: 'Beverly Hills', formatted_address: nil})
      assert_dom_equal "<address>Beverly Hills, California, 90210</address>", helper.place_address(place)
    end
  end


  describe "#comment_date" do
    it "should return the full date when it's older than 4 days" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
          comment = double(Comment, created_at: Time.zone.local(2013, 07, 22, 11, 59))
          helper.comment_date(comment).should == "July 22 at 11:59 am"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 19, 11, 59))
          helper.comment_date(comment).should == "July 19 at 11:59 am"

          comment = double(Comment, created_at: Time.zone.local(2013, 06, 19, 11, 59))
          helper.comment_date(comment).should == "June 19 at 11:59 am"
      end
    end

    it "should return the day of the week if the comment is older than yesterday but newer than 4 days" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
          comment = double(Comment, created_at: Time.zone.local(2013, 07, 23, 00, 00))
          helper.comment_date(comment).should == "Tuesday at 12:00 am"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 24, 16, 40))
          helper.comment_date(comment).should == "Wednesday at  4:40 pm"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 24, 23, 59))
          helper.comment_date(comment).should == "Wednesday at 11:59 pm"
      end
    end

    it "should return 'Yesterday' plus the time if the date is older than 24 horus" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
          comment = double(Comment, created_at: Time.zone.local(2013, 07, 25, 11, 59))
          helper.comment_date(comment).should == "Yesterday at 11:59 am"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 25, 00, 0))
          helper.comment_date(comment).should == "Yesterday at 12:00 am"
      end
    end

    it "should return the number of hours rounded to the lower number" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
          comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 10, 59))
          helper.comment_date(comment).should == "1 hour ago"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 10, 22))
          helper.comment_date(comment).should == "1 hour ago"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 9, 0))
          helper.comment_date(comment).should == "3 hours ago"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 25, 12, 01))
          helper.comment_date(comment).should == "23 hours ago"
      end
    end

    it "should return the number of minutes" do
      Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 0)) do # Simulate current date to Jul 26th
          comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 11, 59))
          helper.comment_date(comment).should == "about 1 minute ago"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 11, 30))
          helper.comment_date(comment).should == "about 30 minutes ago"

          comment = double(Comment, created_at: Time.zone.local(2013, 07, 26, 11, 01))
          helper.comment_date(comment).should == "about 59 minutes ago"
      end
    end

  end
end