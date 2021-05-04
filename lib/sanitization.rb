require "sanitization/version"
require "active_record_ext/sanitization"

module Sanitization
  class Error < StandardError; end
end

ActiveRecord::Base.class_eval do
  include ActiveRecordExt::Sanitization
end
