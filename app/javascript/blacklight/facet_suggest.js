import debounce from "blacklight/debounce";

const FacetSuggest = async (e) => {
  if (e.target.matches('.facet-suggest')) {
    const queryFragment = e.target.value?.trim();
    const facetField = e.target.dataset.facetField;
    if (!facetField) { return; }

    const urlToFetch = `/catalog/facet_suggest/${facetField}/${queryFragment}`
    const response = await fetch(urlToFetch);
    if (response.ok) {
        const blob = await response.blob()
        const text = await blob.text()
    
        const facetArea = document.querySelector('.facet-extended-list');
    
        if (text && facetArea) {
            facetArea.innerHTML = text
        }
    }
  }
};

document.addEventListener('input', debounce(FacetSuggest));

export default FacetSuggest
