require 'forwardable'

module GemLovefest
  class Note
    extend Forwardable
    include DataMapper::Resource

    belongs_to :rubygem, :child_key => [:gem_name]
    belongs_to :user,    :child_key => [:email_address]
    is :list, :scope => [:gem_name]

    property :email_address, String, :key => true
    property :gem_name,      String, :key => true
    property :comment,       Text
    property :created_at,    DateTime

    def_delegators :user, :name, :name=

    validates_format :email_address, :as => :email_address

    def initialize(*args)
      super(*args)
      self.user ||= User.first_or_new(:email_address => email_address)
      self.rubygem ||= Rubygem.first_or_new(:gem_name => gem_name)
    end

  end
end
