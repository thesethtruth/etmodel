class @Router extends Backbone.Router
  routes:
    "demand/:sidebar(/:slide)" : "demand"
    "costs/:sidebar(/:slide)"  : "costs"
    "targets/:sidebar(/:slide)": "targets"
    "supply/:sidebar(/:slide)" : "supply"

  demand:  (sidebar, slide) => @load_slides('demand', sidebar, slide)
  costs:   (sidebar, slide) => @load_slides('costs', sidebar, slide)
  targets: (sidebar, slide) => @load_slides('targets', sidebar, slide)
  supply:  (sidebar, slide) => @load_slides('supply', sidebar, slide)

  load_slides: (tab, sidebar, slide) ->
    url = "/scenario/#{tab}/#{sidebar}/#{slide}"
    $.ajax
      url: url
      dataType: 'script'

  load_default_slides: =>
    key = Backbone.history.getFragment() || 'demand/households'
    [tab, sidebar, slide] = key.split('/')
    @load_slides tab, sidebar, slide
    $("#sidebar h4[data-key=#{tab}]").click()
    $("#sidebar li##{sidebar}").addClass 'active'


