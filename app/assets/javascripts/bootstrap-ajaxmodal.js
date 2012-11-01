//= require bootstrap-modal
!function($) {

  $.fn.ajaxyDialog = function(options) {
    $element = $(this);
  	$element.modal(options);

    var modalFixup = function() {
      if(typeof(options.extractHeader) == 'function') {
        $element.find('.modal-header h3').empty().append(options.extractHeader($element.find('.modal-body')));
      }
      if(typeof(options.extractFooter) == 'function') {
        $element.find('.modal-footer').empty().append(options.extractFooter($element.find('.modal-body')));
      }
      
      $(options.chainAjaxySelector, $element).on('click', function() {
        $element.find('.modal-body').load($(this).attr('href'), function() {

          modalFixup();
        });

        return false;
      });
    }

    $element.on('shown', modalFixup);

    $element.modal('show');
  }

}(jQuery)