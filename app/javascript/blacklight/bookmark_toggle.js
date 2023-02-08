import CheckboxSubmit from 'blacklight/checkbox_submit'

const BookmarkToggle = (e) => {
  if (e.target.matches('[data-checkboxsubmit-target="checkbox"]')) {
    const form = e.target.closest('form')
    if (form) new CheckboxSubmit(form).clicked(e);
  }
};

BookmarkToggle.selector = 'form.bookmark-toggle';

document.addEventListener('click', BookmarkToggle);

export default BookmarkToggle
