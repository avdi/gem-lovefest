begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'datamapper'
require 'dm-is-list'
require 'dm-timestamps'
require 'dm-validations'

$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'gem-lovefest/rubygem'
require 'gem-lovefest/note'
require 'gem-lovefest/user'

