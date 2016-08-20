# Backport the Rails 5 controller test methods to Rails 4
module BackportTest
  [:delete, :get, :post, :put, :patch].each do |http_action|
    define_method(http_action) do |*args|
      (action, rest) = *args
      rest ||= {}
      if rest[:xhr]
        @request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
        @request.env['HTTP_ACCEPT'] ||= [Mime::JS, Mime::HTML, Mime::XML, 'text/xml', Mime::ALL].join(', ')
      end
      super(action, rest[:params])
    end
  end
end
