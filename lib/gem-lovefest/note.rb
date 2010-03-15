module GemLovefest
  class Note
    include DataMapper::Resource

    belongs_to :rubygem, :child_key => [:gem_name]
    belongs_to :user,    :child_key => [:email_address]
    is :list, :scope => [:gem_name]

    attr_accessor :name

    property :email_address, String, :key => true
    property :gem_name,      String, :key => true
    property :comment,       Text
    property :created_at,    DateTime

    validates_format :email_address, :as => :email_address

    before :create do
      gem = Rubygem.first_or_create(:gem_name => gem_name)
      unless gem.saved?
        gem.errors.each do |error|
          errors.add(:gem_name, error)
        end
        throw :halt
      end
    end

    before :create do
      user = User.first_or_create(
        {:email_address => email_address},
        {:name          => name})
      unless user.saved?
        user.errors.each do |error|
          errors.add(:email_address, error)
        end
        throw :halt
      end
    end

  end
end
