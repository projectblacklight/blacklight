# Backport the Rails 5 controller test methods to Rails 4
module BackportTest
  def delete(*args)
    (action, rest) = *args
    rest ||= {}
    if rest[:xhr]
      @request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
    end
    super(action, rest[:params])
  end

  def get(*args)
    (action, rest) = *args
    rest ||= {}
    if rest[:xhr]
      @request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
    end
    super(action, rest[:params])
  end

  def post(*args)
    (action, rest) = *args
    rest ||= {}
    if rest[:xhr]
      @request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
    end
    super(action, rest[:params])
  end

  def put(*args)
    (action, rest) = *args
    rest ||= {}
    if rest[:xhr]
      @request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
    end
    super(action, rest[:params])
  end
end
