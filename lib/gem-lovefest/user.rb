module GemLovefest
  class User
    include DataMapper::Resource
    
    property :email_address, String, :key => true
    property :name,          String
    validates_format :email_address, :as => :email_address

    has n, :notes,    :child_key => [:email_address]
  end
end
