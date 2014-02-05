$.widget 'nmk.reportBuilder',
	options: {
		id: null,
		rows: [],
		columns: [],
		values: [],
		filters: [],
	},

	_create: () ->
		@saved = true
		@id = @options.id
		# Fields search input
		@element.find('#field-search-input').on 'keyup', (e) =>
			value = $(e.target).val().toLowerCase();
			for li in @element.find("#report-fields li:not(.hidden)")
				if $(li).text().toLowerCase().search(value) > -1
					$(li).show()
				else
					$(li).hide()

		@preview = @element.find('#report-container')
		@reportOverlay = $('<div class="report-overlay">').hide().insertAfter(@preview)

		@element.find('.sortable-list').sortable
			receive: (event, ui) =>
				if ui.helper?
					ui.item.addClass('hidden').hide()
					field = {field: ui.item.data('field-id'), label: ui.item.find('.field-label').text(), aggregate: 'sum'}
					$(event.target).find('li[data-field-id="'+ui.item.data('field-id')+'"]').data('field', field)
				true
			update: (event, ui) =>
				@reportModified()
				true
			connectWith: '.sortable-list',
			containment: 'body'
		.droppable
			greedy: true

		# Allow the list items to be removed when dropped outside of the list
		$('body').droppable
			accept: ".sortable-list li"
			drop: ( event, ui ) =>
				$("#report-fields li[data-field-id=\"#{ui.draggable.data('field-id')}\"]").removeClass('hidden').show()
				ui.draggable.remove()

		@element.find(".draggable-list li").draggable
			connectToSortable: ".sortable-list",
			revert: "invalid",
			helper: "clone",
			containment: "#resource-filter-column", 
			scroll: false,
			# The next two events (start/drag) are only to fix this issue: 
			#http://stackoverflow.com/questions/5791886/jquery-draggable-shows-helper-in-wrong-place-when-scrolled-down-page
			start: () ->
				$(this).data "startingScrollTop", $(this).parent().scrollTop()
			drag: (event, ui) ->
				st = parseInt( $(this).data("startingScrollTop") )
				ui.position.top -= $(this).parent().scrollTop() - st

		@element.find('.btn-save-report').on 'click', () =>
			@saveForm()

		$(window).on 'beforeunload', =>
			if not @saved
				'All changes will be lost. Are you sure you want to exit?'


		@_setListItems 'rows', @options.rows
		@_setListItems 'columns', @options.columns
		@_setListItems 'values', @options.values
		@_setListItems 'filters', @options.filters

		@element.on 'click', '.field-settings-btn', (e) =>
			@showFieldSettings $(e.target).closest('.report-field')
			e.stopPropagation()
			false

		@element

	saveForm: () ->
		$.ajax
			url: "/results/reports/#{@id}.js",
			type: 'PUT',
			data: @_reportFormData(),
			success: () =>
				@element.find('.btn-save-report').attr('disabled', true)
				@saved = true

	refreshReportPreview: () ->
		# Simulate the report is updating
		@_showOverlay()
		$.ajax
			url: "/results/reports/#{@id}/preview.js",
			type: 'POST',
			data: @_reportFormData(),
			complete:
				@_hideOverlay()
		, 1000

	reportModified: () ->
		@element.find('.btn-save-report').attr('disabled', false)
		@refreshReportPreview()
		@saved = false

	showFieldSettings: (fieldElement) ->
		if @fieldSettings?
			if @fieldSettings.fieldElement[0] is fieldElement[0]
				return @closeFieldSettings()
			else
				@closeFieldSettings()

		field = fieldElement.data('field')
		listName = fieldElement.closest('ul').attr('id')

		formFields = []
		formFields.push $('<div class="control-group">').
							append($('<label class="control-label">').text('Label'),
								$('<div class="controls">').append(
									$('<input type="text" name="report-field-label">').val(field.label).
										on 'keyup', (e) => 
											field.label = e.target.value
											fieldElement.find('.field-label').text(e.target.value)
											@fieldSettings.changed = true
								)
							)

		if listName in ['report-values']
			formFields.push $('<div class="control-group">').
								append(	$('<label class="control-label">').text('Summarize by'),
										$('<div class="controls">').append(
											$('<select name="report-field-sorting">').append([
													$('<option value="count">Count</option>').attr('selected', field.aggregate is 'count'),
													$('<option value="sum">Sum</option>').attr('selected', field.aggregate is 'sum'),
													$('<option value="avg">Average</option>').attr('selected', field.aggregate is 'avg'),
													$('<option value="max">Max</option>').attr('selected', field.aggregate is 'max'),
													$('<option value="min">Min</option>').attr('selected', field.aggregate is 'min')
												])
												.on 'change', (e) =>
													field.aggregate = $(e.target).val()
													@fieldSettings.changed = true
										)
								)

		@fieldSettings = $('<div class="report-field-settigns">').hide()
			.append(formFields)
			.appendTo(@element)
		@fieldSettings.fieldElement = fieldElement
		@fieldSettings.changed = false
		@_placeFieldSettings()
		@fieldSettings.find('select').chosen()
		@fieldSettings.show()

		$(document).on 'click.reportFieldSettings', =>
			@closeFieldSettings()

		@fieldSettings.on 'click', -> false

	closeFieldSettings: () ->
		if @fieldSettings.changed is true
			@reportModified()
		$(document).off 'click.reportFieldSettings'
		@fieldSettings.remove()
		@fieldSettings = null

	_placeFieldSettings: () ->
		element = @fieldSettings.fieldElement
		leftFix = -parseInt((@fieldSettings.outerWidth()-element.outerWidth())/2)
		@fieldSettings.css({
			position: 'absolute', 
			top: element.position().top+element.outerHeight(),
			left: element.position().left+leftFix
		})

	_getColumns: () -> 
		$.map $('#report-columns li', @element), (column, i) =>
			@_getColumnProperties column

	_getRows: () -> 
		$.map $('#report-rows li', @element), (row, i) =>
			@_getRowProperties row

	_getFilters: () -> 
		$.map $('#report-filters li', @element), (filter, i) =>
			@_getFilterProperties filter

	_getValues: () -> 
		$.map $('#report-values li', @element), (value, i) =>
			@_getValueProperties value

	_getColumnProperties: (column) ->
		$col = $(column)
		field = $col.data('field')
		{field: $col.data('field-id'), label: field.label }

	_getRowProperties: (row) ->
		$row = $(row)
		field = $row.data('field')
		{field: $row.data('field-id'), label: field.label }

	_getFilterProperties: (filter) ->
		$filter = $(filter)
		field = $filter.data('field')
		{field: $filter.data('field-id'), label: field.label }

	_getValueProperties: (value) ->
		$value = $(value)
		field = $value.data('field')
		{field: $value.data('field-id'), label: field.label, aggregate: if field.aggregate? then field.aggregate else 'sum' }

	_setListItems: (list_name, items) ->
		list = $("#report-#{list_name}", @element)
		for item in items
			li = $("#report-fields li[data-field-id=\"#{item.field}\"]").clone()
			li.find('.field-label').text(item.label)
			list.append li.data('field-id', item.field).data('field', item)
			$("#report-fields li[data-field-id=\"#{item.field}\"]").hide()
		true

	_showOverlay: () ->
		@preview.css opacity: 0.5
		@reportOverlay.css 
			position: 'absolute',
			top: @preview.position().top+"px",
			left: @preview.position().left+"px",
			height: @preview.outerHeight()+"px",
			width: @preview.outerWidth()+"px",
			borderColor: '#000'
		.show()

	_hideOverlay: () ->
		@preview.css opacity: 1
		@reportOverlay.hide()

	_reportFormData: () ->
		{ 
			report: {
				columns: @_getColumns(),
				rows: @_getRows(),
				filters: @_getFilters(),
				values: @_getValues()
			}
		}
