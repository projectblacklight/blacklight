// Namespace our global variables and functions
var uvalib = {
  searchEl: "search", // ID of search widget
  searchInCleared: false,
  simpSrchTip: "search for keywords...",
  simpSrchTips: {
	  	'CatalogSearchForm': "Type keywords to find books, videos, audio, reference materials, and more",
		'MusicSearchForm': "Type keywords to find music related materials"
	  },
  balanceSrchInputs: function(e,inputs) { // function to keep search value the same between tabbing
		if(typeof e != 'undefined' && e.type == 'load') {
			uvalib.resetSrchInputs(inputs);
		} else {
			for (var i=0; i<inputs.length; i++) {
				inputs[i].value = this.value;
				YAHOO.util.Dom.removeClass(inputs[i],"dimmed");
			}
		}
  },
  resetSrchInputs: function(inputs) {
		for (var i=0; i<inputs.length; i++) {
			// Add a dimmed hint message to the search input
			//alert(inputs[i].form.id);
			//inputs[i].value = uvalib.simpSrchTip;
			inputs[i].value = uvalib.simpSrchTips[inputs[i].form.id];
			YAHOO.util.Dom.addClass(inputs[i],"dimmed");
		}
  },
  clearSrchInputs: function(e,inputs) {
		for (var i=0; i<inputs.length; i++) {
			if(inputs[i].value == uvalib.simpSrchTips[inputs[i].form.id]) inputs[i].value = '';
			YAHOO.util.Dom.removeClass(inputs[i],"dimmed");
		}
  }
  // Make sure there's no comma after last property, as that breaks js in Safari
}

if (typeof(YAHOO) == "object") { // Don't run any of the YUI stuff unless the YAHOO object exists

var $E = YAHOO.util.Event;
var $D = YAHOO.util.Dom;
var $El = YAHOO.util.Element;

// Make header search tab widget
YAHOO.util.Event.onAvailable(uvalib.searchEl, function() {
		// Build tabview widget from existing markup
		var tabView = new YAHOO.widget.TabView(uvalib.searchEl);
		// Make Yahoo buttons out of regular search submit buttons
		var srchBtns = $D.getElementsByClassName('searchBtn','input','search');
		var srchBtnsYUI = [];
		for(var i=0; i<srchBtns.length; i++) {
			srchBtnsYUI[i] = new YAHOO.widget.Button(srchBtns[i].id,{ id: srchBtns[i].id+'YUI' });
		}
		// Set listeners for the simple search text inputs within the tabs
        var simpSrchInputs = $D.getElementsByClassName('searchIn','input','search');
        $E.on(simpSrchInputs, 'blur', uvalib.balanceSrchInputs, simpSrchInputs);
		$E.on(simpSrchInputs, 'focus', uvalib.clearSrchInputs, simpSrchInputs);
		uvalib.resetSrchInputs(simpSrchInputs);
});

// Make global navigation bar
YAHOO.util.Event.onAvailable('globalNav', function() {
	var expand = new YAHOO.util.Anim('globalNav', { paddingBottom: {from: 0, to: 2, unit: 'em'} }, 0.2, YAHOO.util.Easing.easeOut);
	var contract = new YAHOO.util.Anim('globalNav', { paddingBottom: {from: 2, to: 0, unit: 'em'} }, 0.2, YAHOO.util.Easing.easeOut);
	var fadeIn = new YAHOO.util.Anim('libNav', { opacity: {from: 0, to: 1} }, 1, YAHOO.util.Easing.easeOut);
	var fadeOut = new YAHOO.util.Anim('libNav', { opacity: {from: 1, to: 0} }, 0.2, YAHOO.util.Easing.easeOut);
	var mOpen = false;
	var oTitle = 'Click to hide the below menu of links to U.Va. Libraries';
	var cTitle = 'Click to show a menu of links to U.Va. Libraries';
	function openMenu(e, ln) {
		if(!mOpen) {
			$D.addClass(lli, 'pressed');
			expand.animate();
			expand.onComplete.subscribe(function(){
				$D.setStyle(ln, "left", "0px");
				$D.setStyle(ln, "opacity", "0");
				fadeIn.animate();
			});
			mOpen = true;
			this.setAttribute('title',oTitle);
		} else {
			$D.removeClass(lli, 'pressed')
			fadeOut.animate();
			fadeOut.onComplete.subscribe(function(){
				contract.animate();
				$D.setStyle(ln, "left", "-3000px");
			});
			mOpen = false;
			this.setAttribute('title',cTitle);
		}
	}
	
	var ln = $D.get('libNav');
	var ll = $D.get('LibrariesLink');
	var lli = ll.parentNode;
	var llContent = ll.innerHTML;
	// create first span element
	newllNode = document.createElement('span');
	newllNode.id = 'LibrariesLink';
	newllNode.innerHTML = '<span><span>'+llContent+'</span></span>';
	lli.replaceChild(newllNode,ll);
	var ll = lli.firstChild;
	ll.setAttribute('title',cTitle);
	
	// Add a hover class to the first span, with ID "LibrariesLink"
	$E.on(newllNode, 'mouseover', function(e,obj) { $D.addClass(obj, 'hover'); },newllNode);
	$E.on(newllNode, 'mouseout', function(e,obj) { $D.removeClass(obj, 'hover'); },newllNode);

	//$D.setStyle(ln, "left", "-3000px");
	$E.on(ll, 'click', openMenu, ln);
	
	var globalNavLiEls = $D.get('globalNav').getElementsByTagName('li');
	//alert($D.get('globalNav').childNodes.length);
	for(var i=0; i<globalNavLiEls.length; i++) {
		//alert(globalNavLiEls[i].parentNode.parentNode.parentNode.id);
		if(globalNavLiEls[i].parentNode.parentNode.parentNode.id) {
			if($D.hasClass(globalNavLiEls[i],'first')) {
				$E.on(globalNavLiEls[i], 'mouseover', function(e,obj) { $D.addClass(obj, 'hover-first'); },globalNavLiEls[i]);
				$E.on(globalNavLiEls[i], 'mouseout', function(e,obj) { $D.removeClass(obj, 'hover-first'); },globalNavLiEls[i]);
			} else  {
				$E.on(globalNavLiEls[i], 'mouseover', function(e,obj) { $D.addClass(obj, 'hover'); },globalNavLiEls[i]);
				$E.on(globalNavLiEls[i], 'mouseout', function(e,obj) { $D.removeClass(obj, 'hover'); },globalNavLiEls[i]);
			}
		}
	}
} );
//YAHOO.util.Event.onAvailable('globalNav', uvalib.setupGlobalNav);
/*
uvalib.setupSearchBtns = function() {  
	var srchBtns = $D.getElementsByClassName('searchBtn','input','search');
	var srchBtnsYUI = [];
	for(var i=0; i<srchBtns.length; i++) {
		srchBtnsYUI[i] = new YAHOO.widget.Button(srchBtns[i].id,{ id: srchBtns[i].id+'YUI' });
	}
}*/
/* Make Yahoo buttons out of regular search submit buttons */
//YAHOO.util.Event.onAvailable(uvalib.searchEl, uvalib.setupSearchBtns);

}