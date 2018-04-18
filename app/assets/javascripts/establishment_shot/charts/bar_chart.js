EstablishmentShot.BarChart = (function () {
    'use strict';

    function mouseover() {
        var chart = $(this).parents('.chart'),
            item = $(this).attr('class');

        chart.find('g.series').stop().animate({ 'opacity': 0.3 });
        chart.find('g.series.' + item).stop().animate({ 'opacity': 1.0 });
    }

    function mouseout() {
        var chart = $(this).parents('.chart');

        chart.find('g.series').stop().animate({ 'opacity': 1.0 });
    }

    function drawLegend(info) {
        var key,
            item,
            square,
            listItem,
            legend = $('<div/>').addClass('legend'),
            list   = $('<ul/>'),
            pos    = info.top ? 'bottom' : 'top';

        this.data.forEach(function (serie) {
            listItem = $('<li/>');
            square   = $('<i/>')
                .addClass('fa fa-square')
                .css('color', serie.color);

            if (serie.value > 0) {
                listItem.on('mouseover', mouseover).on('mouseout', mouseout);
            }

            listItem
                .addClass(serie.key)
                .attr('title', serie.value + ' ' + serie.unit)
                .append(square, I18n.t('establishment_shot.legend.' + serie.key));

            list.prepend(listItem);
        });

        legend.css(pos, '0px');

        legend.append(list);
        this.scope.append(legend);
    }

    function color_for(info) {
        var i, found,
            chart = EstablishmentShot.Charts.charts.bar_chart;

        for (i = 0; i < chart.series.length; i++) {
            if (chart.series[i].key === info) {
                found = chart.color_gradient[i];
                break;
            }
        }

        return found || '#000';
    }

    function drawTitle(info) {
        var span,
            chart = this.scope.data('chart'),
            title = $('<h5/>');

        title.append(
            I18n.t('establishment_shot.charts.' + chart)
        );

        if (info.fa_icon) {
            span = $('<span/>').css('color', color_for(chart));
            span.html('&#x' + info.fa_icon);
            title.css('text-align', function () {
                return info.left ? 'right': 'left';
            });

            info.left ? title.append(span) : title.prepend(span);
        }

        if (info.showMaxLabel) {
            this.scope.parents('div.overview').prepend(title);
        } else {
            info.top ? this.scope.prepend(title) : this.scope.append(title);
        }
    }

    function calculateMax(data) {
        return d3.sum(data.map(function(serie) {
            return serie.value;
        }));
    }

    BarChart.prototype = {
        render: function () {
            var chart = this.scope.data('chart'),
                info = EstablishmentShot.Charts.charts[chart],
                unit = this.data[0].unit;

            window.stackedBarChart(
                this.scope[0],
                {
                    width: info.width,
                    height: info.height,
                    series: this.data,
                    title: '',
                    margin: info.margin,
                    showY: info.showY,
                    showMaxLabel: info.showMaxLabel,
                    max: calculateMax(this.data),
                    mouseover: info.mouseover.bind(this.scope),
                    mouseout: info.mouseout.bind(this.scope),
                    formatValue: function (d) {
                        return d + ' ' + unit;
                    }
                }
            );

            drawTitle.call(this, info);
            drawLegend.call(this, info);
        }
    }

    function BarChart(scope, data) {
        this.scope = scope;
        this.data  = data;
    }

    return BarChart;
}());