module Scissor

  class Mencoder < Command
    def initialize(command = 'mencoder', work_dir = nil, save_work_dir = false)
      super(:command => command,
        :work_dir => work_dir,
        :options => { :save_work_dir => save_work_dir })
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
