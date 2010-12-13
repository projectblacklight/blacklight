$(document).ready(function() {
  $('#facets h3').next("ul, div").each(function(){
    var f_content = $(this);
    $(f_content).prev('h3').addClass('twiddle');
    // find all f_content's that don't have any span descendants with a class of "selected"
    if($('span.selected', f_content).length == 0){
      // hide it
      f_content.hide();
    } else {
      $(this).prev('h3').addClass('twiddle-open');
    }

    // attach the toggle behavior to the h3 tag
    $('h3', f_content.parent()).click(function(){
      // toggle the content
      $(this).toggleClass('twiddle-open');
      $(f_content).slideToggle();
    });
  });
});
