import CheckboxSubmit from 'blacklight-frontend/checkbox_submit'

const BookmarkToggle = (e) => {
  const elementType = e.target.getAttribute('data-checkboxsubmit-target');
  if (elementType == 'checkbox' || elementType == 'label') {
    const form = e.target.closest('form');
    if (form) new CheckboxSubmit(form).clicked(e);
    if (e.code == 'Space') e.preventDefault();
  }
};

document.addEventListener('click', BookmarkToggle);
document.addEventListener('keydown', function (e) {
  if (e.key === 'Enter' || e.code == 'Space') { BookmarkToggle(e); } }
);

export default BookmarkToggle
