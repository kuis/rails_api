$.widget 'nmk.reportTableScroller',
	options: {
	},

	_create: () ->
		@offset = 1
		@count = 0
		@cols = $('thead tr:first-child', @element).find('td,th')
		@leftMargin

		# Store the initial widths for each cell
		@element.css({width: 'auto'}) # Make the cells to take their "natural/minimun" width
		$.each @cols, (i, cell) =>
			$(cell).data 'width', $(cell).width()
			$(cell).data 'outer-width', $(cell).outerWidth()
		@element.css({width: '100%'})

		$('.report-arrows a').on 'click.reportTableScroller', (e) =>
			@adjustColumnsSize $(e.target).data('direction')
			false

		@adjustColumnsSize()
		@element.css({'table-layout': 'fixed'})

		$(window).off('resize.reportTableScroller').on 'resize.reportTableScroller', (e) =>
			@adjustColumnsSize()
			true

		@element.on 'click', '.report-collapse-button', (e) =>
			$(e.target).toggleClass('icon-expand').toggleClass('icon-collapse')
			collapsed = $(e.target).hasClass('icon-expand')
			row = $(e.target).closest('tr')
			level = row.data('level')
			next = row.next('tr')
			while next.data('level') > level
				if collapsed
					next.hide().find('.icon-collapse').removeClass('icon-collapse').addClass('icon-expand')
				else if next.data('level') == level+1  # Only show/hide the inmediate children elements
					next.show()
				next = next.next('tr')

			false

		@element.on 'click', '.expand-all', (e) =>
			$(e.target).toggleClass('icon-expand').toggleClass('icon-collapse')
			if $(e.target).hasClass('icon-collapse') # Expand all
				$(e.target).attr('title', 'Collapse All')
				@element.find('tbody tr[data-level]').show()
				@element.find('tbody tr[data-level] .icon-expand').removeClass('icon-expand').addClass('icon-collapse')
			else
				$(e.target).attr('title', 'Expand All')
				@element.find('tbody tr[data-level!=0]').hide()
				@element.find('tbody tr[data-level] .icon-collapse').removeClass('icon-collapse').addClass('icon-expand')

			false
		@

	_destroy: () ->
		$('.report-arrows a').off 'click.reportTableScroller'
		$(window).off 'resize.reportTableScroller'

	adjustColumnsSize: (direction=false) ->
		availableWidth = @element.parent().width()
		if direction is 'right' and (@offset+@count) >= @cols.length
			@offset = @cols.length
			direction = 'left'

		if direction is 'right'
			@offset = @offset+@count
			cols = @cols.get().slice(@offset)
		else if direction is 'left'
			return if this.offset is 1
			cols = @cols.get().slice(0, @offset).reverse()
		else
			cols = @cols.get().slice(@offset)

		width = @count = 0

		for cell in cols
			$cell = $(cell)
			if (availableWidth > width + $cell.data('outer-width')) and (this.offset > 1 or direction isnt 'left')
				width += $cell.data('outer-width')
				@count += 1
				@offset = if direction is 'left' then @offset-1 else @offset
			else
				break

		# If we got to the first cell, check if there are more cells that can fit
		if @offset is 1 and direction is 'left'
			for cell in @cols.get().slice(@offset+@count)
				$cell = $(cell)
				if availableWidth > width + $cell.data('outer-width')
					width += $cell.data('outer-width')
					@count += 1
				else
					break

		if @offset >= @cols.length-1
			for cell in @cols.get().slice(0, @offset).reverse()
				$cell = $(cell)
				if availableWidth > width + $cell.data('outer-width')
					width += $cell.data('outer-width')
					@count += 1
					@offset -= 1
				else
					break

		marginLeft = 0
		for cell in @cols.slice(1, @offset)
			marginLeft -= $(cell).outerWidth()

		@element.css {marginLeft: marginLeft+'px'}

		adjust = (availableWidth-width)/@count
		for cell in @cols.slice(@offset, (@offset+@count))
			$cell = $(cell)
			$cell.css({width: ($cell.data('width')+adjust)+ 'px'})

		if @offset is 1
			$('.report-arrows a[data-direction=left]').addClass 'disabled'
		else
			$('.report-arrows a[data-direction=left]').removeClass 'disabled'

		if (@offset+@count) is @cols.length
			$('.report-arrows a[data-direction=right]').addClass 'disabled'
		else
			$('.report-arrows a[data-direction=right]').removeClass 'disabled'

		true

