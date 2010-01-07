module Scissor

  class Mencoder < Command
    def initialize(command = which('mencoder'), work_dir = nil)
      super(:command => command,
            :work_dir => work_dir
            )
    end

    def concat(args)
      run(["#{args[:input_videos].join(' ')}",
           "-o #{args[:output_video]}",
           "-oac copy",
           "-ovc copy"
      ].join(' '), false, true)
    end
  end
end
