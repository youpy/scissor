module Scissor

  class Ecasound < Command
    def initialize(command = which('ecasound'), work_dir = nil)
      super(:command => command,
            :work_dir => work_dir
            )
      which('ecasound')
    end

    def fragments_to_file(fragments, outfile, tmpdir)
      position = 0.0
      params = []
      ffmpeg = Scissor::FFmpeg.new

      fragments.each_with_index do |fragment, index|
        fragment_filename = fragment.filename
        fragment_duration = fragment.duration

        if !index.zero? && (index % 80).zero?
          run params.join(' ')
          params = []
        end

        fragment_outfile =
          fragment_filename.extname.downcase == '.wav' ? fragment_filename :
          tmpdir + (Digest::MD5.hexdigest(fragment_filename) + '.wav')

        unless fragment_outfile.exist?
          ffmpeg.convert fragment_filename, fragment_outfile
        end

        params <<
          "-a:#{index} " +
          "-i:" +
          (fragment.reversed? ? 'reverse,' : '') +
          "select,#{fragment.start},#{fragment.true_duration},\"#{fragment_outfile}\" " +
          "-o:#{outfile} " +
          (fragment.pitch.to_f == 100.0 ? "" : "-ei:#{fragment.pitch} ") +
          "-y:#{position}"

        position += fragment_duration
      end

      run params.join(' ')
    end

    def mix_files(filenames, outfile)
      params = []
      filenames.each_with_index do |tf, index|
        params << "-a:#{index} -i:#{tf}"
      end

      params << "-a:all -o:#{outfile}"
      run params.join(' ')
    end
  end
end
