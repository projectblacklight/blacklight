This directory should contain solr document extension modules.
These modules should act as adapters for other concrete classes,
in otherwords, keep the main logic of the extension in separate
classes that can be tested by themselves. See the Solr::Document::Marc
module for an example.