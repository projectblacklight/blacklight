import CheckboxSubmit from 'blacklight-frontend/checkbox_submit'

const BookmarkToggle = (e) => {
  const elementType = e.target.getAttribute('data-checkboxsubmit-target');
  if (elementType == 'checkbox' || elementType == 'icon') {
    const form = e.target.closest('form')
    if (form) new CheckboxSubmit(form).clicked(e);
  }
};

document.addEventListener('click', BookmarkToggle);
document.addEventListener('keydown', function (e) {
  if (e.key === 'Enter') { BookmarkToggle(e) } }
);

export default BookmarkToggle
