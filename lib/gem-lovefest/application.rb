require File.expand_path('../gem-lovefest', File.dirname(__FILE__))
require 'sinatra'
require 'addressable/uri'
require 'link_header'
require 'logger'
require 'haml'

set :haml, {:format => :html5}
set :views, File.expand_path('../../views', File.expand_path(File.dirname(__FILE__)))
set :public, File.expand_path('../../public', File.expand_path(File.dirname(__FILE__)))

include GemLovefest

configure do
  set :logger, Logger.new($stdout)
end

configure :test do
  DataMapper.setup(:default, 
    :adapter  => "sqlite3",
    :database => File.expand_path('../../db/test.db', File.dirname(__FILE__)))
end

configure :development do
  DataMapper.setup(:default, 
    :adapter  => "sqlite3",
    :database => File.expand_path('../../db/development.db', File.dirname(__FILE__)))
end

configure :test, :development do
  DataMapper.repository.auto_upgrade!
end

helpers do
  def validation_error_message(resource)
    "Unable to complete your request: \n  - " +
      resource.errors.full_messages.join("\n  - ") +
      "\n"
  end
end

get "/" do
  this_url       = Addressable::URI.parse(request.url)
  notes_url      = this_url.dup
  notes_url.path = "/notes"
  links = LinkHeader.new(
    [[notes_url.to_s, [["rel", "http://gem-love.avdi.org/relations#notes"]]]])
  headers['Link'] = links.to_s
  render :haml, :index, :locals => { 
    :notes => Note.all(:limit => 10, :order => [:created_at.desc]) 
  }
end

post "/notes" do
  note = Note.first_or_new(
    :email_address => params[:email_address], 
    :gem_name      => params[:gem_name],)
  note.comment = params[:comment]
  note.name    = params[:name]
  status note.new? ? 201 : 200
  unless note.save
    error 400, validation_error_message(note)
  end
  headers['Location'] = "/gems/#{note.gem_name}/notes/#{note.position}"
  "Your appreciation for #{note.gem_name} has been recorded!"
end

get "/gems/:gem_name" do |gem_name|
  gem = Rubygem.get(gem_name)
  error 404, "Gem not found" unless gem
  render :haml, :gem, :locals => { 
    :gem       => gem,
    :fan_count => gem.notes.count
  }
end

get "/gems/:gem_name/notes/:position" do |gem_name, position|
  note = Rubygem.get(gem_name).notes.first(:position => position)
  note.comment
end
