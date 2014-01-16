class Api::V1::VenuesController < Api::V1::FilteredController

  resource_description do
    short 'Venues'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the "
    description <<-EOS

    EOS
  end


  api :GET, '/api/v1/venues', "Search for a list of venues"
  param :location, String, :desc => "A pair of latitude and longitude seperated by a comma. This will make the list to include only those that are in a radius of +radius+ kilometers."
  param :campaign, Array, :desc => "A list of campaign ids to filter the results"
  param :page, :number, :desc => "The number of the page, Default: 1"

  description <<-EOS
    Returns a list of venues filtered by the given params. The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

    All the times and dates are returned on the user's timezone.

    *Facets*

    Faceting is a feature of Solr that determines the number of documents that match a given search and an additional criteria

    When <page> is "1", the result will include a list of facets.

    *Facets Results*

    The API returns the facets on the following format:

      [
        {
          label: String,          # Any of: Events, Impressions, Interactions, Promo Hours, Samples, Venue Score, $ Spent, Campaigns, Areas, Brands
          items: [                # List of items for the facet sorted by relevance. (Not included for range filters)
            {
              "label": String,      # The name of the item
              "id": String,         # The id of the item, this should be used to filter the list by this items
              "name": String,       # The param name to be use for filtering the list (campaign, user, team, place, area, status, event_status, etc)
              "count": Number,      # The number of results for this item
              "selected": Boolean   # True if the list is being filtered by this item
            },
            ....
          ],
          min: Number,            # The minimun value for the filter. (Only included for range filters)
          max: Number,            # The maximum value for the filter. (Only included for range filters)
          selected_min: Number,   # The selected minimun value for the filter, this should be used as the default value for the range selectors. (Only included for range filters)
          selected_max: Number    # The selected maximum value for the filter, this should be used as the default value for the range selectors. (Only included for range filters)
        }
      ]

  EOS

  example <<-EOS
  {
      "page": 1,
      "total": 3233,
      "facets": [
          {
              "label": "Events",
              "name": "events_count",
              "min": 0,
              "max": 127,
              "selected_min": null,
              "selected_max": null
          },
          {
              "label": "Impressions",
              "name": "impressions",
              "min": 0,
              "max": 29330,
              "selected_min": null,
              "selected_max": null
          },
          {
              "label": "Interactions",
              "name": "interactions",
              "min": 0,
              "max": 14463,
              "selected_min": null,
              "selected_max": null
          },
          {
              "label": "Promo Hours",
              "name": "promo_hours",
              "min": 0,
              "max": 3447,
              "selected_min": null,
              "selected_max": null
          },
          {
              "label": "Samples",
              "name": "sampled",
              "min": 0,
              "max": 1040,
              "selected_min": null,
              "selected_max": null
          },
          {
              "label": "Venue Score",
              "name": "venue_score",
              "min": 0,
              "max": 100,
              "selected_min": null,
              "selected_max": null
          },
          {
              "label": "$ Spent",
              "name": "spent",
              "min": 0,
              "max": 7758,
              "selected_min": null,
              "selected_max": null
          },
          {
              "label": "Price",
              "items": [
                  {
                      "label": "$",
                      "id": "1",
                      "name": "price",
                      "count": 1,
                      "ordering": 1,
                      "selected": false
                  },
                  {
                      "label": "$$",
                      "id": "2",
                      "name": "price",
                      "count": 1,
                      "ordering": 2,
                      "selected": false
                  },
                  {
                      "label": "$$$",
                      "id": "3",
                      "name": "price",
                      "count": 1,
                      "ordering": 3,
                      "selected": false
                  },
                  {
                      "label": "$$$$",
                      "id": "4",
                      "name": "price",
                      "count": 1,
                      "ordering": 3,
                      "selected": false
                  }
              ]
          },
          {
              "label": "Areas",
              "items": [
                  {
                      "label": "Ann Arbor",
                      "id": 19,
                      "count": 0,
                      "name": "area",
                      "selected": false
                  },
                  {
                      "label": "Asbury Park",
                      "id": 20,
                      "count": 0,
                      "name": "area",
                      "selected": false
                  }
              ]
          },
          {
              "label": "Campaigns",
              "items": [
                  {
                      "label": "ABSOLUT BA FY14",
                      "id": 14,
                      "name": "campaign",
                      "selected": false
                  },
                  {
                      "label": "ABSOLUT Bloody FY14",
                      "id": 57,
                      "name": "campaign",
                      "selected": false
                  }
              ]
          },
          {
              "label": "Brands",
              "items": [
                  {
                      "label": "ABSOLUT Vodka",
                      "id": 25,
                      "name": "brand",
                      "count": 1,
                      "selected": false
                  },
                  {
                      "label": "Aberlour",
                      "id": 6,
                      "name": "brand",
                      "count": 1,
                      "selected": false
                  }
              ]
          }
      ],
      "results": [
          {
              "id": 1523,
              "name": "Bayou Beer Garden New Orleans",
              "formatted_address": "326 North Jefferson Davis Parkway, New Orleans, LA, United States",
              "latitude": 29.97205,
              "longitude": -90.091787,
              "zipcode": "70119",
              "city": "New Orleans",
              "state": "Louisiana",
              "country": "US",
              "events_count": 5,
              "promo_hours": "5.0",
              "impressions": 1100,
              "interactions": 750,
              "sampled": 575,
              "spent": "732.0",
              "score": 93,
              "avg_impressions": "220.0",
              "avg_impressions_hour": "220.0",
              "avg_impressions_cost": "0.67"
          },
          {
              "id": 1835,
              "name": "Just John Club",
              "formatted_address": "4112 Manchester Avenue, St. Louis, MO, United States",
              "latitude": 38.627711,
              "longitude": -90.250814,
              "zipcode": "63110",
              "city": "St Louis",
              "state": "Missouri",
              "country": "US",
              "events_count": 4,
              "promo_hours": "4.0",
              "impressions": 495,
              "interactions": 300,
              "sampled": 200,
              "spent": "905.0",
              "score": 93,
              "avg_impressions": "123.0",
              "avg_impressions_hour": "123.75",
              "avg_impressions_cost": "1.83"
          },
          {
              "id": 1401,
              "name": "The Tap",
              "formatted_address": "815 Harvey Road, College Station, TX, United States",
              "latitude": 30.622055,
              "longitude": -96.312067,
              "zipcode": "77840",
              "city": "College Station",
              "state": "Texas",
              "country": "US",
              "events_count": 1,
              "promo_hours": "1.0",
              "impressions": 250,
              "interactions": 90,
              "sampled": 69,
              "spent": "216.0",
              "score": 93,
              "avg_impressions": "250.0",
              "avg_impressions_hour": "250.0",
              "avg_impressions_cost": "0.86"
          },
          ....
      ]
  }
  EOS
  def index
    collection
  end


  api :GET, '/api/v1/venues/search', "Search for a list of venues matching a term"
  param :term, String, :desc => "The search term", required: true

  description <<-EOS
    Returns a list of venues matching the search +term+ ordered by relevance limited to 10 results.

    The response consist on a list or the following attributes:
    * *id*: the place id or reference that have to be sent when creating/updating events, this can be either an number or a large string.
    * *value*: the description of the venue, including the name and address
    * *label*: this exactly the same as +value+
  EOS

  example <<-EOS
  [{
      "value":"Bar None, 1980 Union Street, San Francisco, CA, United States",
      "label":"Bar None, 1980 Union Street, San Francisco, CA, United States",
      "id":90
    },
   {
      "value":"Bar None, 98 3rd Avenue, New York, NY, United States",
      "label":"Bar None, 98 3rd Avenue, New York, NY, United States",
      "id":"CnRpAAAAT5JxPtj5WPge6_MkN0q55Ati4lj_HSCXLwx9ZS-zh6B-YF9fLsizZtjXAiPA-loJKiNNh0JxNUIdMGJUwk5lqR1jxhzGmPWBp01bCOGfRdFS3KKybejTmvlFI7EeTjV_g_9b_aAAYtl9OOYS4ght5BIQ0Z0OUWz2Zgnyx2ln6BVEvhoUaZ9DhhS2g56S4ZYfogaJjs0rb4o||07f11bfbcd5a70e34d2dceef794e6d07aa34b7ee"
    }]
  EOS
  def search
    @venues = Place.combined_search(company_id: current_company.id, q: params[:term], search_address: true)

    render json: @venues.first(10)
  end

  protected
    def permitted_search_params
      params.permit({campaign: []}, :location, :radius)
    end
end
