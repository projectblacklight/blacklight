import debounce from "blacklight-frontend/debounce";

const FacetSuggest = async (e) => {
  if (e.target.matches('.facet-suggest')) {
    const queryFragment = e.target.value?.trim();
    const facetField = e.target.dataset.facetField;
    const facetArea = document.querySelector('.facet-extended-list');
    const prevNextLinks = document.querySelectorAll('.prev_next_links');

    if (!facetField) { return; }

    // Get the search params from the current query so the facet suggestions
    // can retain that context.
    const facetSearchContext = e.target.dataset.facetSearchContext;
    const url = new URL(facetSearchContext, window.location.origin);

    // Drop facet.page so a filtered suggestion list will always start on page 1
    url.searchParams.delete('facet.page');
    // add our queryFragment for facet filtering
    url.searchParams.append('query_fragment', queryFragment);

    const facetSearchParams = url.searchParams.toString();
    const basePathComponent = url.pathname.split('/')[1];

    const urlToFetch = `/${basePathComponent}/facet_suggest/${facetField}?${facetSearchParams}`;

    const response = await fetch(urlToFetch);
    if (response.ok) {
        const blob = await response.blob()
        const text = await blob.text()

        if (text && facetArea) {
            facetArea.innerHTML = text
        }
    }

    // Hide the prev/next links when a user enters text in the facet
    // suggestion input. They don't work with a filtered list.
    prevNextLinks.forEach(element => {
      element.classList.toggle('invisible', !!queryFragment);
    });

    // Add a class to distinguish suggested facet values vs. regular.
    facetArea.classList.toggle('facet-suggestions', !!queryFragment);
  }
};

document.addEventListener('input', debounce(FacetSuggest));

export default FacetSuggest
