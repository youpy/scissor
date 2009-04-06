$:.unshift File.dirname(__FILE__) + '/../lib/'

require 'scissor'

def fixture(filename)
  File.dirname(__FILE__) + '/fixtures/' + filename
end
