ENV['RACK_ENV'] = 'test'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'gem-lovefest'
require 'spec'
require 'spec/autorun'
require 'nokogiri'

Spec::Runner.configure do |config|
  def have_tags(selector, pattern=//, &block)
    HaveTags.new(selector, pattern, &block)
  end
end

class HaveTags
  def initialize(selector, pattern=//, &block)
    @selector = selector
    @pattern  = pattern
    @block    = block || lambda{true}
  end

  def matches?(subject)
    if subject.respond_to?(:body)
      @doc = Nokogiri::HTML(subject.body)
    else
      @doc = subject
    end
    matches = @doc.search(@selector)
    @expectation = "elements matching '#{@selector}' to be found"
    if matches.empty?
      @failed = true
    elsif !matches.any?{|m| @pattern === m.text}
      @expectation = "an element matching '#{@selector}' to have text matching #{@pattern.inspect}"
      @failed = true
    end
    !@failed
  end

  def selector_and_pattern
    pattern = @pattern==// ? 'any text' : "text #{@pattern.inspect}"
    "elements matching '#{@selector}' with #{pattern}"
  end

  def failure_message_for_should
    "expected #{@expectation} in:\n #{@doc.to_s}"
  end

  def negative_failure_message
    "did not expect #{@expectation} in:\n #{@doc.to_s}"
  end
end

