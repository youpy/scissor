module Scissor
  class Sequence
    def initialize(pattern, duration_per_step)
      @pattern = pattern
      @duration_per_step = duration_per_step
    end

    def apply(scissors)
      result = Scissor()

      @pattern.split(//).each do |c|
        if scissors.include?(c.to_sym)
          scissor = scissors[c.to_sym]

          if @duration_per_step > scissor.duration
            result += scissor
            result += Scissor.silence(@duration_per_step - scissor.duration)
          else
            result += scissors[c.to_sym].slice(0, @duration_per_step)
          end
        else
          result += Scissor.silence(@duration_per_step)
        end
      end

      result
    end
  end
end
