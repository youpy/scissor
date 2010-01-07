class Float
  def to_msec
    (self * 1000).to_i
  end

  # for Scissor::FFmpeg#cut
  def to_ffmpegtime
    min = 60
    hour = 60 * min

    h = self.to_i / hour
    m = (self.to_i - h * hour) / min
    sec = self.to_i - h * hour - m * min
    msec = (self * 1000 % 1000).to_i
    sprintf "%02d:%02d:%02d.%03d", h, m, sec, msec
  end
end
