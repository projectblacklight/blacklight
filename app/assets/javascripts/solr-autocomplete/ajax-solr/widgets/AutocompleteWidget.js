(function ($) {

AjaxSolr.AutocompleteWidget = AjaxSolr.AbstractTextWidget.extend({
  afterRequest: function () {
    $(this.target).find('input').unbind().removeData('events').val('');

    var self = this;
    self.cutList = 15
    self.minLen = 0
        
    var callback = function (response) {
      
       self.list = [];
  	       for (var i = 0; i < self.fields.length; i++) {
			var field = self.fields[i];
			for (var facet in response.facet_counts.facet_fields[field]) {
			  self.list.push({
			    field: field,
			    value: facet,
			    label: facet + '(' + response.facet_counts.facet_fields[field][facet] + ')'
			  });
			}
		      }
         
      
      self.requestSent = false;
      $(self.target).find('input').autocomplete('destroy').autocomplete({
        source: function(request, response) {
         var params = [ 'rows=0&facet=true&facet.limit=1000&facet.mincount=1&json.nl=map&facet.sort=count' ];
    	 for (var i = 0; i < self.fields.length; i++) {
	      params.push('facet.field=' + self.fields[i]);
	 }
         params.push('facet.prefix=' + request.term);
         params.push('q=' + '');
         $.getJSON(self.manager.solrUrl + 'select?' + params.join('&') + '&wt=json&json.wrf=?', request, 
         function( data, status, xhr ) {
		 self.list = [];
		       for (var i = 0; i < self.fields.length; i++) {
			var field = self.fields[i];
			for (var facet in data.facet_counts.facet_fields[field]) {
			  self.list.push({
			    field: field,
			    value: facet,
			    label: facet + '(' + data.facet_counts.facet_fields[field][facet] + ')'
			  });
			}
		      }	
		 var results = self.list;
		response(results.slice(0, self.cutList));
		}
         );
        
},
        minLength:self.minLen,
        select: function(event, ui) {
          if (ui.item) {
            self.requestSent = true;
            if (self.manager.store.addByValue('fq', ui.item.field + ':' + AjaxSolr.Parameter.escapeValue(ui.item.value))) {
              //self.doRequest();
            }
          }
        }
      });

      // This has lower priority so that requestSent is set.
      $(self.target).find('input').bind('keydown', function(e) {
        if (self.requestSent === false && e.which == 13) {
          var value =wt=json& $(this).val();
          if (value && self.set(value)) {
            self.doRequest();
          }
        }
      });
    } // end callback

    var params = [ 'rows=0&facet=true&facet.limit='  + self.cutList + '&facet.mincount=1&json.nl=map&facet.sort=count' ];
    for (var i = 0; i < this.fields.length; i++) {
      params.push('facet.field=' + this.fields[i]);
    }
    var values = this.manager.store.values('fq');
    for (var i = 0; i < values.length; i++) {
      params.push('fq=' + encodeURIComponent(values[i]));
    }
    params.push('q=' + this.manager.store.get('q').val());
    $.getJSON(this.manager.solrUrl + 'select?' + params.join('&') + '&wt=json&json.wrf=?', {}, callback);
  }
});

})(jQuery);
