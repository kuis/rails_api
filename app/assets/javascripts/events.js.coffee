jQuery ->
  $(document).delegate ".task-completed-checkbox", "click", ->
    $(@form).submit()

  $(document).delegate '#tasks-list td a.data-resource-details-link', 'click', (e) ->
    $row = $(this).parents('tr');
    if $("##{$row.attr('id')}_comments").length
      $("##{$row.attr('id')}_comments").toggle()
      e.stopImmediatePropagation()

    else
      $(this).removeAttr('data-remote')

    e.preventDefault();
    return false

  # EVENTS INDEX
  $('#toggle-events-view a').on 'click', ->
    $('#toggle-events-view a').removeClass 'active'
    $(this).addClass('active').tab 'show'
    if $(this).attr('href') is '#map-view' and not map
      initializeMap()
      $('.FixedHeader_Cloned').hide()
    else
      $('.FixedHeader_Cloned').show()
      eventsTable.fnDraw()



  map = null
  markersArray = []
  events = null

  initializeMap = ->
    mapOptions = {
      center: new google.maps.LatLng(-34.397, 150.644),
      zoom: 5,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions)
    placeMarkers()

  $(document).on 'events-list:changed', (e, list) ->
    events = list
    placeMarkers()


  placeMarkers = ->
    if map
      for marker in markersArray
        marker.setMap null

      bounds = new google.maps.LatLngBounds()

      for event in events
        if event.place? and event.place.latitude?
          placeLocation = new google.maps.LatLng(event.place.latitude,event.place.longitude)
          marker = new google.maps.Marker({
            map:map,
            draggable:false,
            title: event.place.name,
            animation: google.maps.Animation.DROP,
            position: placeLocation
          })
          markersArray.push marker

          marker.theInfowindow = new google.maps.InfoWindow {
              content: $('<div>')
                      .append($('<b>').append(if event.campaign? then event.campaign.name else ''))
                      .append($('<br>')).append(event.start_at)
                      .append($('<br>')).append(if event.place? then event.place.formatted_address else '')
                      .append($('<br>')).append($('<a>', {'href': event.links.show}).text('View Details')).html()
          }

          google.maps.event.addListener marker, 'click', () ->
            for marker in markersArray
              marker.theInfowindow.close()

            this.theInfowindow.open map, this

          # Automatically center/zoom the map according to the markers :)
          bounds.extend marker.position

      if events.length > 0
        map.fitBounds bounds



