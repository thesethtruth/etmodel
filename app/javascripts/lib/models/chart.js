/* DO NOT MODIFY. This file was compiled Wed, 07 Mar 2012 12:27:44 GMT from
 * /Users/paozac/Sites/etmodel/app/coffeescripts/lib/models/chart.coffee
 */

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  this.Chart = (function(_super) {

    __extends(Chart, _super);

    function Chart() {
      this.render = __bind(this.render, this);
      Chart.__super__.constructor.apply(this, arguments);
    }

    Chart.prototype.defaults = {
      'container': 'current_chart'
    };

    Chart.prototype.initialize = function() {
      this.series = (function() {
        switch (this.get('type')) {
          case 'block':
            return new BlockChartSeries();
          case 'scatter':
            return new ScatterChartSeries();
          default:
            return new ChartSeries();
        }
      }).call(this);
      this.bind('change:type', this.render);
      return this.render();
    };

    Chart.prototype.render = function() {
      var type;
      type = this.get('type');
      this.view = (function() {
        switch (type) {
          case 'bezier':
            return new BezierChartView({
              model: this
            });
          case 'horizontal_bar':
            return new HorizontalBarChartView({
              model: this
            });
          case 'horizontal_stacked_bar':
            return new HorizontalStackedBarChartView({
              model: this
            });
          case 'mekko':
            return new MekkoChartView({
              model: this
            });
          case 'waterfall':
            return new WaterfallChartView({
              model: this
            });
          case 'vertical_stacked_bar':
            return new VerticalStackedBarChartView({
              model: this
            });
          case 'grouped_vertical_bar':
            return new GroupedVerticalBarChartView({
              model: this
            });
          case 'policy_bar':
            return new PolicyBarChartView({
              model: this
            });
          case 'line':
            return new LineChartView({
              model: this
            });
          case 'block':
            return new BlockChartView({
              model: this
            });
          case 'vertical_bar':
            return new VerticalBarChartView({
              model: this
            });
          case 'html_table':
            return new HtmlTableChartView({
              model: this
            });
          case 'scatter':
            return new ScatterChartView({
              model: this
            });
          default:
            return new HtmlTableChartView({
              model: this
            });
        }
      }).call(this);
      this.view.update_title();
      return this.view;
    };

    Chart.prototype.results = function(exclude_target) {
      var out, series;
      if (exclude_target === void 0 || exclude_target === null) {
        series = this.series.toArray();
      } else {
        series = this.non_target_series();
      }
      out = _(series).map(function(serie) {
        return serie.result();
      });
      if (this.get('percentage')) {
        out = _(out).map(function(serie) {
          var scaled;
          scaled = [[serie[0][0], serie[0][1] * 100], [serie[1][0], serie[1][1] * 100]];
          return scaled;
        });
      }
      return out;
    };

    Chart.prototype.colors = function() {
      return this.series.map(function(serie) {
        return serie.get('color');
      });
    };

    Chart.prototype.labels = function() {
      return this.series.map(function(serie) {
        return serie.get('label');
      });
    };

    Chart.prototype.values_present = function() {
      var exclude_target_series;
      exclude_target_series = true;
      return _.map(this.results(exclude_target_series), function(result) {
        return result[0][1];
      });
    };

    Chart.prototype.values_future = function() {
      var exclude_target_series;
      exclude_target_series = true;
      return _.map(this.results(exclude_target_series), function(result) {
        return result[1][1];
      });
    };

    Chart.prototype.values = function() {
      return _.flatten([this.values_present(), this.values_future()]);
    };

    Chart.prototype.value_pairs = function() {
      return this.series.map(function(serie) {
        return serie.result_pairs();
      });
    };

    Chart.prototype.non_target_series = function() {
      return this.series.reject(function(serie) {
        return serie.get('is_target_line');
      });
    };

    Chart.prototype.target_series = function() {
      return this.series.select(function(serie) {
        return serie.get('is_target_line');
      });
    };

    Chart.prototype.target_results = function() {
      return _.flatten(_.map(this.target_series(), function(serie) {
        return serie.result()[1][1];
      }));
    };

    Chart.prototype.series_hash = function() {
      return this.series.map(function(serie) {
        return {
          label: serie.get('label'),
          present_value: serie.present_value(),
          future_value: serie.future_value()
        };
      });
    };

    Chart.prototype.formatted_series_hash = function() {
      var _this = this;
      return this.series.map(function(serie) {
        return {
          label: serie.get('label'),
          present_value: Metric.autoscale_value(serie.present_value(), _this.get('unit'), 2),
          future_value: Metric.autoscale_value(serie.future_value(), _this.get('unit'), 2)
        };
      });
    };

    return Chart;

  })(Backbone.Model);

  this.ChartList = (function(_super) {

    __extends(ChartList, _super);

    function ChartList() {
      ChartList.__super__.constructor.apply(this, arguments);
    }

    ChartList.prototype.model = Chart;

    ChartList.prototype.initialize = function() {
      $.jqplot.config.enablePlugins = true;
      return this.setup_callbacks();
    };

    ChartList.prototype.change = function(chart) {
      var old_chart;
      old_chart = this.first();
      if (old_chart !== void 0) this.remove(old_chart);
      return this.add(chart);
    };

    ChartList.prototype.load = function(chart_id) {
      var url,
        _this = this;
      App.etm_debug('Loading chart: #' + chart_id);
      if (this.current_id() === parseInt(chart_id)) return;
      url = "/output_elements/" + chart_id + ".js?" + (timestamp());
      return $.getScript(url, function() {
        if (chart_id !== _this.current_default_chart) {
          $("a.default_charts").show();
        } else {
          $("a.default_charts").hide();
        }
        if (_this.current().view.can_be_shown_as_table()) {
          $("a.toggle_chart_format").show();
        } else {
          $("a.toggle_chart_format").hide();
        }
        $("#output_element_actions a.chart_info").attr("href", "/descriptions/charts/" + chart_id);
        $("#output_element_actions").removeClass();
        $("#output_element_actions").addClass(_this.first().get("type"));
        return App.call_api();
      });
    };

    ChartList.prototype.current_id = function() {
      return parseInt(this.first().get('id'));
    };

    ChartList.prototype.current = function() {
      return this.first();
    };

    ChartList.prototype.setup_callbacks = function() {
      var _this = this;
      $("a.default_charts").live('click', function() {
        _this.user_selected_chart = null;
        _this.load(_this.current_default_chart);
        return false;
      });
      $("a.pick_charts").live('click', function(e) {
        var chart_id, url;
        chart_id = $(e.target).parents('a').data('chart_id');
        _this.user_selected_chart = chart_id;
        url = "/output_elements/select_chart/" + chart_id + "?" + (timestamp());
        return $.ajax({
          url: url,
          method: 'get',
          beforeSend: function() {
            return close_fancybox();
          }
        });
      });
      return $("a.toggle_chart_format").live('click', function() {
        _this.current().view.toggle_format();
        return false;
      });
    };

    return ChartList;

  })(Backbone.Collection);

  window.charts = new ChartList();

}).call(this);
