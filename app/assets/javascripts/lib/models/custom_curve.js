/* globals $ Backbone I18n */

(function (window) {
  'use strict';

  var preservedAttrs = new Set(['key', 'overrides', 'type']);

  var CustomCurve = Backbone.Model.extend({
    idAttribute: 'key',

    /**
     * Returns if there is a file attached for this curve.
     */
    isAttached: function () {
      return this.get('attached');
    },

    /**
     * Returns true if the curve was imported from another scenario.
     */
    isFromScenario: function () {
      return !$.isEmptyObject(this.get('source_scenario'));
    },

    /**
     * The translated, human-readable name for the curve.
     */
    translatedName: function () {
      return I18n.t('custom_curves.names.' + this.id);
    },

    /**
     * Removes all attributes and returns the CustomCurve to an unattached
     * state.
     */
    purge: function () {
      for (var key in this.attributes) {
        if (!preservedAttrs.has(key) && this.has(key)) {
          if (key === 'attached') {
            this.set('attached', false);
          } else {
            this.unset(key);
          }
        }
      }
    },
  });

  var CustomCurveCollection = Backbone.Collection.extend({
    model: CustomCurve,

    getOrBuild: function (id) {
      if (!this.get(id)) {
        this.add(new CustomCurve({ key: id }));
      }

      return this.get(id);
    },
  });

  // Globals -----------------------------------------------------------------

  window.CustomCurve = CustomCurve;
  window.CustomCurveCollection = CustomCurveCollection;
})(window);
