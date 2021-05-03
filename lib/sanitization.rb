require "sanitization/version"
require "active_record/sanitization"

module Sanitization
  class Error < StandardError; end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Sanitization
end

