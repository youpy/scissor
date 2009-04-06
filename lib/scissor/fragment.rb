require 'pathname'

module Scissor
  class Fragment
    attr_reader :filename, :start, :duration

    def initialize(filename, start, duration, reverse = false)
      @filename = Pathname.new(filename)
      @start = start
      @duration = duration
      @reverse = reverse

      freeze
    end

    def reversed?
      @reverse
    end

    def create(remaining_start, remaining_length)
      new_fragment = nil

      if remaining_start >= duration
        remaining_start -= duration
      else
        if remaining_start + remaining_length >= duration
          new_fragment = self.class.new(
            filename,
            start + remaining_start,
            duration - remaining_start)

          remaining_length -= (duration - remaining_start)
          remaining_start = 0
        else
          new_fragment = self.class.new(
            filename,
            start + remaining_start,
            remaining_length)

          remaining_start = 0
          remaining_length = 0
        end
      end

      return new_fragment, remaining_start, remaining_length
    end
  end
end
