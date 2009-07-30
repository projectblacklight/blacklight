require 'rubygems'
require 'json'
require 'open-uri'
 
q = <<-EOF
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX dbp: <http://dbpedia.org/>
SELECT ?person ?page ?born ?dead
WHERE { ?person dbp:death ?dead .
?person foaf:page ?page .
OPTIONAL { ?person dbp:birth ?born}
FILTER ( ?dead <= "1970-01-01"^^xsd:dateTime) }
ORDER BY DESC(?dead)
LIMIT 1
EOF

endpoint = 'http://dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fdbpedia.org&format=json&query='
result = JSON.parse(open(endpoint + URI.escape(q)).read)
puts result.inspect