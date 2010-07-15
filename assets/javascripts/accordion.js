$(document).ready(function() {
    $('#facets ul, #facets h3 + form').each(function(){
   var f_content = $(this);
   // find all f_content's that don't have any span descendants with a class of "selected"
   if($('span.selected', f_content).length == 0){
        // hide it
        f_content.hide();
        // attach the toggle behavior to the h3 tag
        $('h3', f_content.parent()).click(function(){
           // toggle the content
           $(f_content).slideToggle();
       });
   }
});
});