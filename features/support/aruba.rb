# -*- encoding : utf-8 -*-
require 'aruba/cucumber'

Before do
    @aruba_timeout_seconds = 240
end

Before ('@really_slow_process') do
    @aruba_timeout_seconds = 240
end
