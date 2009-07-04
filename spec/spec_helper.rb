$:.unshift File.dirname(__FILE__) + '/../lib/'

require 'scissor'

def fixture(filename)
  Pathname.new(File.dirname(__FILE__) + '/fixtures/' + filename).realpath
end
