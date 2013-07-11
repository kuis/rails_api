$.widget 'nmk.filteredList', {
	options: {
		source: false,
		filtersUrl: false,
		filters: false,
		onChange: false,
		includeCalendars: false,
		includeAutoComplete: false,
		autoCompletePath: '',
		defaultParams: [],
		selectDefaultDate: false
	},

	_create: () ->
		@element.addClass('filter-box')
		@form = $('<form action="#" method="get">')
			.appendTo(@element).submit (e)->
				e.preventDefault()
				e.stopPropagation()
				false
		@form.data('serializedData', null)


		if @options.includeAutoComplete
			@_addAutocompleteBox()

		if @options.includeCalendars
			@_addCalendars()

		@formFilters = $('<div class="form-facet-filters">').appendTo(@form)
		if @options.filters
			@setFilters(@options.filters)

		@filtersPopup = false

		@listContainer = $(@options.listContainer)

		@defaultParams = @options.defaultParams
		@_parseQueryString()
		@loadFacets = true
		firstTime = true
		$(window).on 'popstate', =>
			if firstTime
				firstTime = false
			else
				@_reloadFilters()
				@_parseQueryString()
				@_filtersChanged(false)

		$(window).on 'resize scroll', () =>
			if @filtersPopup
				@_positionFiltersOptions()

		@infiniteScroller = false
		@_loadPage(1)
		@_loadFilters()

		@defaultParams = []
		@initialized = true

	destroy: ->
		@_closeFilterOptions()
		if @infiniteScroller
			@element.infiniteScrollHelper 'destroy'


	disableScrolling: ->
		if @infiniteScroller
			@listContainer.infiniteScrollHelper 'disableScrolling'

	enableScrolling: ->
		if @infiniteScroller
			@listContainer.infiniteScrollHelper 'enableScrolling'


	_loadFilters: ->
		params = @buildParams()
		$.getJSON @options.filtersUrl, params, (json) =>
			@setFilters json.filters

	getFilters: () ->
		p = @form.serializeArray()
		for param in @defaultParams
			p.push param

		if @loadFacets
			p.push {'name': 'facets', 'value': true}
			@loadFacets=false
		p

	setFilters: (filters) ->
		@formFilters.html('')
		for filter in filters
			if filter.items.length > 0 or (filter.top_items? and filter.top_items.length)
				@addFilterSection filter

	addFilterSection: (filter) ->
		items = filter.items
		top5 = filter.top_items
		$list = $('<ul>')
		$filter = $('<div class="filter-wrapper">').data('name', filter.name).append($('<h3>').text(filter.label), $list)
		i = 0
		if not top5
			optionsCount = items.length
			top5 = []
			while i < optionsCount
				option = items[i]
				if option.count > 0 and (i < 5 or option.selected)
					top5.push option
				i++
		else
			optionsCount = top5.length + items.length

		for option in @_sortOptionsAlpha(top5)
			$list.append(@_buildFilterOption(option).change( (e) => @_filtersChanged() ))

		@formFilters.append($filter)
		if optionsCount > 5
			$ul = $('<ul class="sf-menu sf-vertical">')
			$trigger = $('<a>',{href: '#', class:'more-options-link'}).text('More').click (e)=>
				if not $ul.hasClass('sf-js-enabled')
					list = @_buildFilterOptionsList(filter, $filter)
					$ul.find('li').append(list)
					$trigger.superfish({cssArrows: false, disableHI: true})
					$trigger.superfish('show')
				false
			$('<div>').append($ul.append($('<li>').append($trigger))).insertAfter($filter)

			$filter
		items = @_sortOptionsAlpha(items)
		$filter.data('filter', filter)

	_sortOptionsAlpha: (options) ->
		options.sort (a, b) ->
			if a.ordering? or b.ordering?
				if not a.ordering
					return 1

				if not b.ordering
					return -1

				if a.ordering == b.ordering
					return 0
				return  if a.ordering > b.ordering then 1 else -1

			if a.label == b.label
				return 0

			return if a.label > b.label then 1 else  -1

	# Display the popout list of options after the user clicks
	# on the "More" button
	_showFilterOptions: (filterWrapper) ->
		if @filtersPopup
			@_closeFilterOptions()

		filter = filterWrapper.data('filter')
		items = @_buildFilterOptionsList(filter, filterWrapper)

		if items? and items.find('li').length > 0
			@filtersPopup = $('<div class="filter-box more-options-popup">').append(items).insertBefore filterWrapper
			bootbox.modalClasses = 'modal-med'
			@filtersPopup.data('wrapper', filterWrapper)

			$(document).on 'click.filterbox', ()  => @_closeFilterOptions()

			@_positionFiltersOptions()

	_positionFiltersOptions: () ->
		reference = @filtersPopup.data('wrapper')
		maxHeight = $(window).height() - 200
		@filtersPopup.css({'max-height': $(window).height()-200})
		if (@filtersPopup.offset().top + @filtersPopup.height() > $(window).scrollTop()+$(window).height())
			@filtersPopup.css({'position': 'fixed', 'bottom': '0px'})
		else if $(window).scrollTop()+200 >= @filtersPopup.offset().top
			@filtersPopup.css({'position': 'fixed', 'top': '200px'})


		@filtersPopup.css {
			'max-height': ($(window).height()-200) + 'px'
		}

	_closeFilterOptions: () ->
		if @filtersPopup
			@filtersPopup.remove()
		$(document).off 'click.filterbox'

	_buildFilterOptionsList: (list, filterWrapper) ->
		$list = null
		if list? and list.items? and list.items.length
			items = {}
			for option in list.items
				if (option.count > 0 or (option.items? and option.items.length)) and
				filterWrapper.find('input:checkbox[name^="'+option.name+'"][value="'+option.id+'"]').length == 0
					$option = @_buildFilterOption(option)
					group = if option.group then option.group else '__default__'
					items[group] ||= []
					items[group].push $option
					$option.bind 'click.filter', (e) =>
						e.stopPropagation()
						true
					.find('input[type=checkbox]').bind 'change.filter', (e) =>
						$checkbox = $(e.target)
						listItem = $($(e.target).parents('li')[0])
						listItem.find('ul').remove()
						$checkbox.unbind 'change.filter'
						listItem.unbind 'click.filter'
						$checkbox.change (e) => @_filtersChanged()
						listItem.find('.checker').show()
						@_filtersChanged()
						$checkbox.attr('checked', true)
						parentList = $(listItem.parents('ul')[0])
						filterWrapper.find('ul').append listItem
						if parentList.find('li').length == 0
							parentList.remove()
						listItem.effect 'highlight'

						# if @filtersPopup.find('li').length == 0
						# 	@_closeFilterOptions()
						# 	filterWrapper.find('.more-options-link').remove()
					if child = @_buildFilterOptionsList(option, filterWrapper)
						$option.append child

			$list = $('<ul>')
			for group, children of items
				if children.length > 0
					if group isnt '__default__'
						$list.append $('<li class="options-list-group">').text(group)
					$list.append children
		$list


	_buildFilterOption: (option) ->
		$('<li>').append($('<label>').append($('<input>',{type:'checkbox', value: option.id, name: "#{option.name}[]", checked: (option.selected is true or option.selected is 'true')}), option.label))


	_addAutocompleteBox: () ->
		previousValue = '';
		@acInput = $('<input type="text" name="ac" class="search-query no-validate" placeholder="Search" id="search-box-filter">')
			.appendTo(@form)
			.on 'blur', () =>
				if @searchHidden.val()
					@acInput.hide()
					@searchLabel.show()
		@acInput.bucket_complete {
			source: @_getAutocompleteResults,
			sourcePath: @options.autoCompletePath,
			select: (event, ui) =>
				@_reloadFilters()
				@_autoCompleteItemSelected(ui.item)
			minLength: 2
		}
		@searchHiddenLabel = $('<input type="hidden" name="ql">').appendTo(@form).val('')
		@searchHidden = $('<input type="hidden" name="q">').appendTo(@form).val('')
		@searchLabel = $('<div class="search-filter-label">')
			.append($('<span class="term">'))
			.append($('<span class="close">').append(
				$('<i class="icon-remove">').click =>
					@_cleanSearchFilter()
					@_filtersChanged()
				))
			.css('width', @acInput.width()+'px').appendTo(@form).hide()
			.click =>
				@searchLabel.hide()
				@acInput.show()
				@acInput.focus()

	_getAutocompleteResults: (request, response) ->
		params = {q: request.term}
		$.get @options.sourcePath, params, (data) ->
			response data
		, "json"

	_autoCompleteItemSelected: (item) ->
		@searchHidden.val "#{item.type},#{item.value}"
		cleanedLabel = item.label.replace(/(<([^>]+)>)/ig, "");
		@searchHiddenLabel.val cleanedLabel
		@acInput.hide().val ''
		@searchLabel.show().find('span.term').html cleanedLabel
		@_filtersChanged()
		false

	_cleanSearchFilter: () ->
		if @searchHidden
			@searchHidden.val ""
			@searchHiddenLabel.val ""
			@acInput.show().val ""
			@searchLabel.hide().find('span.term').text ''

		if @initialized
			@_reloadFilters()

		false

	_addCalendars: () ->
		@startDateInput = $('<input type="hidden" name="start_date" class="no-validate">').appendTo @form
		@endDateInput = $('<input type="hidden" name="end_date" class="no-validate">').appendTo @form
		container = $('<div class="dates-range-filter">').appendTo @form
		container.datepick {
			rangeSelect: true,
			monthsToShow: 1,
			changeMonth: false,
			defaultDate: new Date(),
			selectDefaultDate: @options.selectDefaultDate,
			prevText: '<',
			nextText: '>',
			showOtherMonths: true,
			selectOtherMonths: true,
			renderer: $.extend(
						{}, $.datepick.defaultRenderer,
						{picker: '<div class="datepick">' +
								'<div class="datepick-nav">{link:prev}{link:next}</div>{months}' +
								'{popup:start}<div class="datepick-ctrl">{link:clear}{link:close}</div>{popup:end}' +
								'<div class="datepick-clear-fix"></div></div>'}),
			onSelect: (dates) =>
				start_date = @_formatDate(dates[0])
				@startDateInput.val start_date

				@endDateInput.val ''
				if dates[0].toLocaleString() != dates[1].toLocaleString()
					end_date = @_formatDate(dates[1])
					@endDateInput.val end_date

				if @initialized == true
					@_reloadFilters()
					@_filtersChanged()
		}


	_formatDate: (date) ->
		"#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"

	_parseDate: (date) ->
		parts = date.split('/')
		new Date(parts[2], parseInt(parts[0])-1, parts[1],0,0,0)

	_filtersChanged: (updateState=true) ->
		if @options.source
			@reloadData
		if @form.data('serializedData') != @form.serialize()
			@form.data('serializedData', @form.serialize())
			@_loadPage(1)
			if updateState
				history.pushState('data', '', document.location.protocol + '//' + document.location.host + document.location.pathname + '?' +@form.data('serializedData'));

			if @options.onChange
				@options.onChange(@)

	buildParams: (params=[]) ->
		data = @getFilters()
		for param in data
			params.push(param)
		params

	reloadData: () ->
		@doneLoading = false
		@element.find('tbody').html ''
		if @infiniteScroller
			@element.infiniteScrollHelper 'resetPageCount'
		@_loadPage 1
		@

	_loadPage: (page) ->
		params = [
			{'name': 'page', 'value': page},
			{'name':'sorting','value': @options.sorting},
			{'name':'sorting_dir','value': @options.sorting_dir}
		]
		params = @buildParams(params)

		if @jqxhr
			@jqxhr.abort()

		@doneLoading = false
		if page is 1
			if @infiniteScroller
				@element.infiniteScrollHelper 'resetPageCount'
			@listContainer.html('')

		@jqxhr = $.get @options.source, params, (response) =>
			$response = $('<div>').append(response)
			$items = $response.find('div[data-content="items"]')
			if @options.onItemsLoad
				@options.onItemsLoad($response, page)

			@listContainer.append($items.html())

			@_pageLoaded(page, $items)

		true

	_pageLoaded: (page, response) ->
		@doneLoading = true
		if @options.onItemsChange
			@options.onItemsChange(response)

		if page == 1 and response.data('pages') > 1  and !@infiniteScroller
			totalPages = response.data('pages')
			@infiniteScroller = @listContainer.infiniteScrollHelper {
				loadMore: (page) =>
					if page <= totalPages && @doneLoading
						@_loadPage(page)
					else
						false

				doneLoading: =>
					@doneLoading
			}

	_parseQueryString: () ->
		@initialized = false
		@_cleanSearchFilter()
		query = window.location.search.replace(/^\?/,"")
		if query != ''
			vars = query.split('&')
			dates = [new Date()]
			for qvar in vars
				pair = qvar.split('=')
				name = decodeURIComponent(pair[0])
				value = decodeURIComponent((if pair.length>=2 then pair[1] else '').replace(/\+/g, '%20'))
				if @options.includeCalendars and value and name in ['start_date', 'end_date']
					date = @_parseDate(value)
					if name is 'start_date' and value
						dates[0] = date
					else
						dates[1] = date
				else
					field = @form.find("[name=\"#{name}\"]")
					if field.length
						if field.attr('type') == 'checkbox'
							console.log('checking checkboxes not implemented yet!!')
						else
							field.val(value)
					else
						@defaultParams.push {'name': name, 'value': value}
			@form.find('.dates-range-filter').datepick('setDate', dates)
		if @searchHidden and @searchHidden.val()
			@acInput.hide()
			@searchLabel.show().find('.term').text @searchHiddenLabel.val()

		@initialized = true

	_reloadFilters: () ->
		@loadFacets = true
		if @defaultParams.length == 0
			@defaultParams = $.map(@formFilters.find('input[name="status[]"]:checked'), (checkbox, index) -> {'name': 'status[]', 'value': checkbox.value})
		@formFilters.html('')
		@form.data('serializedData','')
		@_loadFilters()
}



$.widget "custom.bucket_complete", $.ui.autocomplete, {
	_renderMenu: ( ul, results ) ->
		for bucket in results
			if bucket.value.length > 0
				ul.append( "<li class='ui-autocomplete-category'>" + bucket.label + "</li>" );
				for item in bucket.value
					@_renderItemData ul, item
	_renderItem: ( ul, item ) ->
		$( "<li>", {class: item.type})
			.append( $( "<a>" ).html( item.label ) )
			.appendTo( ul )
}