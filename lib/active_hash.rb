require 'active_support'

begin
  require 'active_support/core_ext'
rescue
end

begin
  require 'active_model'
  require 'active_model/naming'
rescue LoadError
end

require 'active_hash/base'
require 'associations/associations'
require 'enum/enum'
