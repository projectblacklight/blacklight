$(document).observe('dom:loaded', function() {
	// Setup search-during-typing.
	new Form.Element.Observer('search', 0.3, function(element, value) {
		performSearch();
	});
	
	// Remove the default search box value when the user puts the focus on
	// the search box for the first time.
	var search_box = $('search');
	if ($F('search') == 'Enter search terms...') {
		search_box.observe('focus', function() {
			if (search_box.hasClassName('untouched')) {
				search_box.removeClassName('untouched');
				search_box.value = '';
			}
		});
	} else {
		search_box.removeClassName('untouched');
	}
});

function searchInIndex(query) {
	var i;
	var results = [];
	query = query.toLowerCase();
	for (i = 0; i < search_index.length; i++) {
		if (search_index[i].method.indexOf(query) != -1) {
			results.push(search_index[i]);
		}
	}
	return results;
}

function buildHtmlForResults(results) {
	var html = "";
	var i;
	for (i = 0; i < results.length; i++) {
		html += '<li>' + results[i].html + '</li>';
	}
	return html;
}

function performSearch() {
	var query = $F('search');
	if (query == '') {
		$('index-entries').show();
		$('search-results').hide();
	} else {
		var results = searchInIndex(query);
		$('search-results').update(buildHtmlForResults(results));
		$('index-entries').hide();
		$('search-results').show();
	}
	return false;
}
