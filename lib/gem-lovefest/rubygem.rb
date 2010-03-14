module GemLovefest
  class Rubygem
    include DataMapper::Resource

    property :gem_name, String, :key => true

    validates_with_method :gem_name, :method => :validate_gem_name_known

    has n, :notes, :child_key => [:gem_name]

    def validate_gem_name_known
      !gem_matches.empty? ||
        [false, "gem '#{gem_name}' could not be found"]
    end

    def self.fetcher_maker
      @fetcher_maker ||= lambda { Gem::SpecFetcher.fetcher }
    end

    def self.fetcher_maker=(proc)
      @fetcher_maker = proc
    end

    private

    def gem_matches
      return @gem_matches if defined?(@gem_matches)
      fetcher  = self.class.fetcher_maker.call
      @gem_matches = fetcher.fetch(Gem::Dependency.new(gem_name))
    end

  end
end
