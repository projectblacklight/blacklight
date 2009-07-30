# Ported from John Nunemaker's Scrobbler Gem (http://scrobbler.rubyforge.org/)

require 'net/https'

module REST
	class Connection
		def initialize(base_url, args = {})
			@base_url = base_url
			@username = args['username']
			@password = args['password']
			@app_id   = args['app_id']
		end

		def get(resource, args = nil)
			request(resource, "get", args)
		end

		def post(resource, args = nil)
			request(resource, "post", args)
		end

		def request(resource, method = "get", args = nil)
			url = URI.join(@base_url, resource)

			if args = args.update('appid' => @app_id)
				# TODO: What about keys without value?
				url.query = args.map { |k,v| "%s=%s" % [URI.encode(k), URI.encode(v)] }.join("&")
			end
						
			case method
			when "get"
				req = Net::HTTP::Get.new(url.request_uri)
			when "post"
				req = Net::HTTP::Post.new(url.request_uri)
			end

			if @username and @password
				req.basic_auth(@username, @password)
			end

			http = Net::HTTP.new(url.host, url.port)
			http.use_ssl = (url.port == 443)

			res = http.start() { |conn| conn.request(req) }
			res.body
		end
	end
end