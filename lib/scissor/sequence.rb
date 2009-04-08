module Scissor
  class Sequence
    def initialize(pattern, duration_per_step)
      @pattern = pattern
      @duration_per_step = duration_per_step
    end

    def apply(instruments)
      result = Scissor()

      @pattern.split(//).each do |c|
        if instruments.include?(c.to_sym)
          instrument = instruments[c.to_sym]

          if instrument.is_a?(Proc)
            instrument = instrument.call(c)
          end

          if @duration_per_step > instrument.duration
            result += instrument
            result += Scissor.silence(@duration_per_step - instrument.duration)
          else
            result += instrument.slice(0, @duration_per_step)
          end
        else
          result += Scissor.silence(@duration_per_step)
        end
      end

      result
    end
  end
end
