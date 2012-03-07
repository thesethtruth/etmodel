class @Chart extends Backbone.Model
  defaults:
    'container': 'current_chart'

  initialize : ->
    @series = switch @get('type')
      when 'block' then new BlockChartSeries()
      when 'scatter' then new ScatterChartSeries()
      else new ChartSeries()
    @bind('change:type', @render)
    @render()

  render : =>
    type = @get('type')
    @view = switch (type)
      when 'bezier'                 then new BezierChartView({model : this})
      when 'horizontal_bar'         then new HorizontalBarChartView({model : this})
      when 'horizontal_stacked_bar' then new HorizontalStackedBarChartView({model : this})
      when 'mekko'                  then new MekkoChartView({model : this})
      when 'waterfall'              then new WaterfallChartView({model : this})
      when 'vertical_stacked_bar'   then new VerticalStackedBarChartView({model : this})
      when 'grouped_vertical_bar'   then new GroupedVerticalBarChartView({model : this})
      when 'policy_bar'             then new PolicyBarChartView({model : this})
      when 'line'                   then new LineChartView({model : this})
      when 'block'                  then new BlockChartView({model : this})
      when 'vertical_bar'           then new VerticalBarChartView({model : this})
      when 'html_table'             then new HtmlTableChartView({model : this})
      when 'scatter'                then new ScatterChartView({model : this})
      else new HtmlTableChartView({model : this})
    @view.update_title()
    @view

  # @return [ApiResultArray] = [
  #   [[2010,0.4],[2040,0.6]],
  #   [[2010,20.4],2040,210.4]]
  # ]
  results : (exclude_target) ->
    if (exclude_target == undefined || exclude_target == null)
      series =  @series.toArray()
    else
      series =  @non_target_series()
    out = _(series).map (serie) ->
      serie.result()

    # policy goal charts show percentages but the gqueries return values
    # in the [0,1] range. Let's take care of that
    if @get('percentage')
      out = _(out).map (serie) ->
        scaled = [
          [
            serie[0][0],
            serie[0][1] * 100
          ],
          [
            serie[1][0],
            serie[1][1] * 100
          ]
        ]
        return scaled
    out

  colors : ->
    @series.map (serie) -> serie.get('color')

  labels : ->
    @series.map (serie) -> serie.get('label')

  # @return [Float] Only values of the present
  values_present: ->
    exclude_target_series = true
    _.map @results(exclude_target_series), (result) ->  result[0][1]

  # @return [Float] Only values of the future
  values_future : ->
    exclude_target_series = true
    _.map @results(exclude_target_series), (result) -> result[1][1]

  # @return [Float] All possible values. Helpful to determine min/max values
  values : ->
    _.flatten([@values_present(), @values_future()])

  # @return [[Float,Float]] Array of present/future values [Float,Float]
  value_pairs :->
    @series.map (serie) -> serie.result_pairs()

  non_target_series : ->
    @series.reject (serie) -> serie.get('is_target_line')

  target_series : ->
    @series.select (serie) -> serie.get('is_target_line')

  # @return Array of present and future target
  target_results : ->
    _.flatten _.map(@target_series(), (serie) -> serie.result()[1][1])

  # @return Array of hashes {label, present_value, future_value}
  series_hash : ->
    @series.map (serie) ->
      res = serie.result()
      out =
        label : serie.get('label'),
        present_value : res[0][1],
        future_value : res[1][1]
      out

class @ChartList extends Backbone.Collection
  model : Chart

  initialize: ->
    $.jqplot.config.enablePlugins = true
    @setup_callbacks()

  change : (chart) ->
    old_chart = @first()
    @remove(old_chart) if old_chart != undefined
    @add(chart)

  load : (chart_id) ->
    App.etm_debug('Loading chart: #' + chart_id)
    # if chart_id == currently shown chart, skip.
    return if @current() == parseInt(chart_id)
    url = "/output_elements/#{chart_id}.js?#{timestamp()}"
    $.getScript url, =>
      # show/hide default chart button
      if chart_id != @current_default_chart
        $("a.default_charts").show()
      else
        $("a.default_charts").hide()
      # update chart information link
      $("#output_element_actions a.chart_info").attr("href", "/descriptions/charts/#{chart_id}")
      # update the position of the output_element_actions
      $("#output_element_actions").removeClass()
      $("#output_element_actions").addClass(@first().get("type"))
      App.call_api()

  # returns the current chart id
  current : ->
    parseInt(@first().get('id'))

  setup_callbacks: ->
    $("a.default_charts").live 'click', =>
      @user_selected_chart = null
      @load(@current_default_chart)
      false

    $("a.pick_charts").live 'click', (e) =>
      chart_id = $(e.target).parents('a').data('chart_id')
      @user_selected_chart = chart_id
      url = "/output_elements/select_chart/#{chart_id}?#{timestamp()}"
      $.ajax
        url: url
        method: 'get'
        beforeSend: ->
          close_fancybox()

window.charts = new ChartList()
