require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'sinatra'
require 'link_header'
require 'gem-lovefest/application'
require 'rack/test'

module GemLovefest
  describe "application" do
    include Rack::Test::Methods

    def app
      Sinatra::Application
    end

    before :each do
      @fetcher = stub("Gem Fetcher", :fetch => ["not empty!"])
      Rubygem.fetcher_maker = lambda { @fetcher }
      @transaction = DataMapper.repository.transaction
      @transaction.begin
      DataMapper.repository.adapter.push_transaction(@transaction)
    end

    after :each do
      @transaction.rollback
      DataMapper.repository.adapter.pop_transaction
    end

    describe "GET /" do
      def do_request
        get "/"
      end

      it "should succeed" do
        do_request
        last_response.should be_ok
      end

      it "should have a link header to the notes resource" do
        do_request
        links      = LinkHeader.parse(last_response['Link'].to_s)
        notes_link = links.find_link(
          ["rel", "http://gem-love.avdi.org/relations#notes"])
        notes_url  = notes_link.href
        notes_url.should == "http://example.org/notes"
      end

      context "with some recent notes" do
        before do
          11.times do |i|
            Note.create(
              :email_address => "user#{i}@example.org",
              :gem_name      => "gem#{i}",
              :comment       => "Comment #{i}",
              :created_at    => Time.mktime(1970,1,i+1))
          end
        end

        it "should show the notes" do
          do_request
          (1..10).each do |n|
            last_response.body.should include("Comment #{n}")
          end
        end
      end
    end

    describe "POST /notes" do
      def do_request(comment="COMMENT", options={})
        post("/notes", {
            :email_address => "TEST_EMAIL@example.org",
            :gem_name      => "TEST_GEM",
            :comment       => comment
          }.merge(options))
      end
      
      it "should succeed" do
        do_request
        last_response.should be_successful
      end

      it "should save a note" do
        lambda do
          do_request
        end.should change{Note.count}.by(1)
      end

      it "should write the submitted email address" do
        do_request
        Note.first(:email_address => "TEST_EMAIL@example.org").should_not be_nil
      end

      it "should write the submitted gem name" do
        do_request
        Note.first(:gem_name => "TEST_GEM").should_not be_nil
      end

      it "should write the submitted comment" do
        do_request
        note = Note.get("TEST_EMAIL@example.org", "TEST_GEM")
        note.comment.should == "COMMENT"
      end

      it "should allow updates to comments" do
        do_request
        do_request("COMMENT2")
        note = Note.get("TEST_EMAIL@example.org", "TEST_GEM")
        note.comment.should == "COMMENT2"
      end

      it "should return a 201 created if new" do
        do_request
        last_response.status.should == 201
      end

      it "should return a 200 if updating" do
        do_request
        do_request("COMMENT2")
        last_response.status.should == 200
      end

      it "should return an error 400 if email is blank" do
        do_request("COMMENT", :email_address => "")
        last_response.status.should == 400
      end

      it "should return an error 400 if gem name is blank" do
        do_request("COMMENT", :gem_name => "", :email_address => "")
        last_response.status.should == 400
      end

      it "should return an error 400 if the email address is invalid" do
        do_request("COMMENT", :email_address =>  "FOO")
        last_response.status.should == 400
      end

      it "should return an error 400 if the gem is unknown" do
        @fetcher.should_receive(:fetch).and_return([])
        do_request
        last_response.status.should == 400
      end

      it "should return a URL for the posted note" do
        do_request
        last_response.headers.should include('Location')
      end

      it "should make the new note accessible" do
        do_request
        location = last_response.headers['Location']
        get location
        last_response.should be_ok
        last_response.body.should include("COMMENT")
      end

    end

  end
end
