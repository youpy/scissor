module Scissor
  class Fragment
    attr_reader :filename, :start, :duration

    def initialize(filename, start, duration, reverse = false)
      @filename = filename
      @start = start
      @duration = duration
      @reverse = reverse

      freeze
    end

    def reversed?
      @reverse
    end
  end
end
