$(function() {
	$('#SearchForm').submit(function(){
		var data = $(this).formSerialize();
		var loc = String(window.location);
		// This keeps the url the same,
		// but switches out the query string
		// with the new form params query string
		loc = loc.replace(/\?.*/, '');
		$('body').append(loc + data);
		window.location = loc + '?' + data;
		return false;
	});
	
	/*var loc=String(window.location);
	if( loc.indexOf('/music') == -1 ){
		
		$('#FlareFacetList .flare_facet_values ul').hide();

		$('#FlareFacetList .flare_facet_title').hover(
			function(){
				$(this).attr('style', 'background-color:lightgray;');
			},
			function(){
				$(this).attr('style', 'background-color:none;');
			}
		);

		$('#FlareFacetList .flare_facet_title').click(function() {
			var $values = $(this).next();
			var $visible = $('.flare_facet_values ul:visible');
			if ($visible.length) {
				$visible.hide('fast', function() {
					$values.find('ul').show('fast');
				});
			} else {
				$values.find('ul').show('fast');
			}
		});
	}*/
});
