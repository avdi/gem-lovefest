require File.expand_path('../gem-lovefest', File.dirname(__FILE__))
require 'sinatra'
require 'addressable/uri'
require 'link_header'
require 'logger'
require 'datamapper'
require 'dm-is-list'

class Rubygem
  include DataMapper::Resource

  property :gem_name, String, :key => true

  has n, :notes, :child_key => [:gem_name]
end

class Note
  include DataMapper::Resource

  belongs_to :rubygem, :child_key => [:gem_name]
  is :list, :scope => [:gem_name]

  property :email_address, String, :key => true
  property :gem_name,      String, :key => true
  property :comment,       Text

  validates_format :email_address, :as => :email_address
  validates_with_method :gem_name, :method => :validate_gem_name_known

  before :create do
    Rubygem.create(:gem_name => gem_name)
  end

  def self.fetcher_maker
    @fetcher_maker ||= lambda { Gem::SpecFetcher.fetcher }
  end

  def self.fetcher_maker=(proc)
    @fetcher_maker = proc
  end

  def validate_gem_name_known
    !gem_matches.empty? ||
      [false, "gem '#{gem_name}' could not be found"]
  end

  private

  def gem_matches
    return @gem_matches if defined?(@gem_matches)
    fetcher  = self.class.fetcher_maker.call
    results = fetcher.fetch(Gem::Dependency.new(gem_name))
  end

end

configure do
  set :logger, Logger.new($stdout)
end

configure :test do
  DataMapper.setup(:default, 
    :adapter  => "sqlite3",
    :database => File.expand_path('../../db/test.db', File.dirname(__FILE__)))
  Note.auto_migrate!
  Rubygem.auto_migrate!
end

helpers do
  def validation_error_message(resource)
    "Unable to complete your request: \n  - " +
      resource.errors.full_messages.join("\n  - ")
  end
end

get "/" do
  this_url       = Addressable::URI.parse(request.url)
  notes_url      = this_url.dup
  notes_url.path = "/notes"
  links = LinkHeader.new(
    [[notes_url.to_s, [["rel", "http://gem-love.avdi.org/relations#notes"]]]])
  headers['Link'] = links.to_s
  "Welcome to Gem Love"
end

post "/notes" do
  note = Note.first_or_new(
      :email_address => params[:email_address], 
      :gem_name      => params[:gem_name])
  note.comment = params[:comment]
  status note.new? ? 201 : 200
  unless note.save
    error 400, validation_error_message(note)
  end
  headers['Location'] = "/gems/#{note.gem_name}/notes/#{note.position}"
end

get "/gems/:gem_name/notes/:position" do |gem_name, position|
  note = Rubygem.get(gem_name).notes.first(:position => position)
  note.comment
end
