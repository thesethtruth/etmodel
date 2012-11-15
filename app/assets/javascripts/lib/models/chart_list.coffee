class @ChartList extends Backbone.Collection
  model : Chart

  initialize: ->
    $.jqplot.config.enablePlugins = true
    @container = $("#charts_wrapper")
    @template = _.template $('#chart-holder-template').html()

    # We can have multiple charts. This hash keeps track ok which chart holders
    # are being used
    @chart_holders = {}
    @setup_callbacks()

  # Loads a chart into a DOM element making an AJAX request. Will create the
  # container if needed
  #
  # chart_id  - id of the chart
  # holder_id - id of the dom element that will hold the chart. If null then a
  #             new chart holder will be created
  # options   - hash with some options (default: {})
  #             alternate   - id of the chart to load if the first one fails.
  #                           Watch out for loops!
  #             force       - (re)load the chart entirely
  #             header      - show or hide the chart header (default: true)
  #             locked      - flag the chart as locked (default: false)
  #             as_table    - render the chart as a table (default: false). Only
  #                           some chart types have this feature!
  #             ignore_lock - don't overwrite the lock flag. This might be
  #                           needed on the initial render, where we want to
  #                           plot the charts and preserve the locks
  #             wait        - don't fire the API request immediately
  #
  # Returns the newly created chart object or false if something went wrong
  load: (chart_id, holder_id = null, options = {}) =>
    # if the chart is already there...
    if ((@chart_holders[holder_id] == chart_id) && !options.force)
      return false

    # if we want to replace a locked chart...
    locked_charts = App.settings.get 'locked_charts'
    if existing = locked_charts[holder_id]
      if options.force
        @get('existing').toggle_lock(false)
      else
        return false unless options.ignore_lock

    App.debug """Loading chart: ##{chart_id} in #{holder_id}
               #{window.location.origin}/admin/output_elements/#{chart_id}"""

    $.ajax
      url: "/output_elements/#{chart_id}"
      success: (data) =>
        holder_id = @add_container_if_needed(holder_id, options)

        # Create the new Chart
        settings = _.extend {}, data.attributes, {
            container: holder_id
            html: data.html # tables and block chart
            locked: options.locked
            as_table: options.as_table
          }
        new_chart = new Chart settings

        if !new_chart.supported_by_current_browser()
          # try opening the alternative, but watch out for loops!
          if options.alternate && options.alternate != chart_id
            @load options.alternate, holder_id
          else
            # sorry, no chart to load...
            alert I18n.t('output_elements.common.old_browser')
          return false

        # Remember what we were showing in that position
        if old_chart = @chart_holders[holder_id]
          old_chart.delete()
          @remove old_chart

        @chart_holders[holder_id] = new_chart
        @add new_chart
        # Pass the gqueries to the chart
        for s in data.series
          s.owner = holder_id
          new_chart.series.add(s)

        App.call_api() unless options.wait
    @last()

  # Returns the chart held in a holder. This assumes a chart can be shown only
  # once. I guesss this is the desired behaviour
  #
  chart_in_holder: (holder_id) =>
    @get @chart_holders[holder_id]

  # restores the default chart for the current slide
  #
  load_default: =>
    @chart_in_holder('holder_0').toggle_lock(false)
    @load @default_chart_id, 'holder_0'

  # This is called right after the app bootstrap. And renders the default
  # chart and the other optional locked charts.
  # There is some (ugly) logic to keep track of which charts should have the
  # locked flag on and which not
  #
  load_charts: =>
    # The accordion takes care of setting @default_chart_id
    settings = App.settings.get 'locked_charts'

    # safe copy of the settings hash
    charts_to_load = _.extend {}, settings

    # is the default chart locked?
    unless default_chart_locked = settings.holder_0
      # if not then use the default chart
      if @default_chart_id
        charts_to_load.holder_0 = @default_chart_id

    ordered_charts = _.keys(charts_to_load).sort()
    for holder in ordered_charts
      chart = charts_to_load[holder]
      # The chart string has this format:
      #     XXX-YYY
      # XXX is the chart id, while YYY is 'T' if the chart must be shown as
      # a table
      [id, format] = "#{chart}".split '-'

      locked = if (holder != 0)
        true
      else
        default_chart_locked

      if id && holder
        @load(id, holder, {
          locked: locked,
          as_table: (format == 'T'),
          # the initial render should ignore the lock check: render the charts
          # but don't remove the locks, which is what `force: true` would do
          ignore_lock: true,
          wait: false
        })

  # adds a chart container, unless it is already in the DOM. Returns the
  # holder_id
  #
  # holder_id - id of the container to add. If null it will be generated
  # header    - boolean to show or hide the header bar. Usually passed by the
  #             load() method above. Dashboard popups set it to false, regular
  #             charts to true
  #
  add_container_if_needed: (holder_id = null, options = {}) =>
    if !holder_id
      timestamp = (new Date()).getTime()
      holder_id = "holder_#{timestamp}"

    if @container.find("##{holder_id}").length == 0
      new_chart = @template(
        title: 'foo'
        chart_id: 0
        holder_id: holder_id
        header: options.header)
      @container.append new_chart
    holder_id

  # This stuff could be moved to the view, but a document-scoped event binding
  # prevents memory leaks and will be called just once.
  #
  setup_callbacks: ->
    # Pick a chart from the chart picker popup
    #
    $(document).on "click", "a.pick_charts", (e) =>
      holder_id = $(e.target).parents('a').data('chart_holder')
      chart_id = $(e.target).parents('a').data('chart_id')
      @load chart_id, holder_id
      close_fancybox()

    # Toggle chart lock
    #
    $(document).on 'click', "a.lock_chart", (e) =>
      e.preventDefault()
      # which chart are we talking about?
      holder_id = $(e.target).parents(".chart_holder").data('holder_id')
      if chart = @chart_in_holder(holder_id)
        chart.toggle_lock()

    # Remove chart
    #
    $(document).on 'click', 'a.remove_chart', (e) =>
      e.preventDefault()
      holder_id = $(e.target).parents(".chart_holder").data('holder_id')
      $(".chart_holder[data-holder_id=#{holder_id}]").remove()
      chart = @get @chart_holders[holder_id]
      if chart
        chart.delete()
        @remove chart

    # Toggle chart/table format
    #
    $(document).on 'click', 'a.table_format, a.chart_format', (e) =>
      e.preventDefault()
      holder_id = $(e.target).parents(".chart_holder").data('holder_id')
      @chart_in_holder(holder_id).toggle_format()

    # Restore the default chart
    #
    $(document).on 'click', 'a.default_chart', (e) =>
      e.preventDefault()
      @load_default()
