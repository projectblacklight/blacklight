# frozen_string_literal: true

pin_all_from File.expand_path("../app/javascript/blacklight", __dir__), under: "blacklight"

# Allow importing Blacklight via blacklight-frontend. See https://github.com/projectblacklight/blacklight/pull/3371
pin "blacklight-frontend", to: "blacklight/index.js"
