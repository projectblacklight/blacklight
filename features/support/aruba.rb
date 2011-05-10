require 'aruba/cucumber'

Before do
    @aruba_timeout_seconds = 60
end

Before ('@really_slow_process') do
    @aruba_timeout_seconds = 120
end
