require 'pathname'

module Scissor
  class Fragment
    attr_reader :filename, :start, :pitch, :pan

    def initialize(filename, start, duration, reverse = false, pitch = 100, stretch = false, pan = 50)
      @filename = Pathname.new(filename).realpath
      @start = start
      @duration = duration
      @reverse = reverse
      @pitch = pitch
      @is_stretched = stretch
      @pan = pan

      freeze
    end

    def duration
      @duration * (100 / pitch.to_f)
    end

    def original_duration
      @duration
    end

    def reversed?
      @reverse
    end

    def stretched?
      @is_stretched
    end

    def create(remaining_start, remaining_length)
      if remaining_start >= duration
        return [nil, remaining_start - duration, remaining_length]
      end

      have_remain_to_return = (remaining_start + remaining_length) >= duration

      if have_remain_to_return
        new_length = duration - remaining_start
        remaining_length -= new_length
      else
        new_length = remaining_length
        remaining_length = 0
      end

      new_fragment = self.class.new(
        filename,
        start + remaining_start * pitch.to_f / 100,
        new_length * pitch.to_f / 100,
        false,
        pitch,
        stretched?,
        pan)

      return [new_fragment, 0, remaining_length]
    end
  end
end
