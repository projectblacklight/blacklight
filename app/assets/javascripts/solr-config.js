var Manager;

(function ($) {

  $(function () {
    Manager = new AjaxSolr.Manager({
		//solrUrl: 'http://evolvingweb.ca/solr/reuters/'
		solrUrl: 'http://127.0.0.1:8983/solr/'
    });
        
    Manager.addWidget(new AjaxSolr.AutocompleteWidget({
      id: 'text',
      target: '#search',
      fields: [ 'text' ]
    }));

    Manager.init();
    //Manager.store.addByValue('q', '*:*');
    Manager.store.addByValue('q', '');
    Manager.doRequest();
    
  });

})(jQuery);
