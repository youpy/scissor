# -*- coding: utf-8 -*-
require 'open4'
require 'logger'
require 'timeout'
require 'tmpdir'

module Scissor
  class Command
    include Loggable

    attr_accessor :work_dir, :command

    class Error < StandardError; end
    class CommandFailed < Error; end
    class UnknownFormat < Error; end

    def initialize(args)
      default_options = {
        :save_work_dir => false
      }

      @options = default_options.merge(args[:options] || {})
      @work_dir = args[:work_dir] || Scissor.workspace || Dir.tmpdir + "/scissor-work-" + $$.to_s
      @work_dir = Pathname.new(@work_dir)
      @work_dir.mkpath
      @command = args[:command] =~ /\// ? args[:command] : which(args[:command])
    end

    def cleanup
      @work_dir.rmtree if @work_dir.exist?
    end

    def _run_command(full_command, force = false, ignore_error = false)
      logger.debug("run_command: #{full_command}")

      result = ''
      status = nil
      error = ''

      begin
        status = Open4.popen4(full_command) do |pid, stdin, stdout, stderr|
          stdin.close

          ios = [stdout, stderr]

          until ios.empty?
            IO.select(ios)[0].each do |io|
              case io
              when stdout
                result += io.read
              when stderr
                error += io.read
              end

              ios.delete(io) if io.eof?
            end
          end

          logger.debug(error) unless ignore_error

          if force && !error.empty?
            result = error
          end
        end
      ensure
        cleanup unless @options[:save_work_dir]
      end

      if !status.nil? && status.exitstatus != 0 && !force
        raise CommandFailed, "cmd:#{full_command}, err:#{error}"
      end

      return result
    end

    def _run_hash(option, force = false, ignore_error = false)
      option_str = [@command, [option.keys.map {|k| "#{k} #{option[k]}"}].flatten].join(' ')
      _run_command(option_str, force, ignore_error)
    end

    # パラメタ指定順番意識するものもあるので
    def _run_str(option_str, force = false, ignore_error = false)
      _run_command([@command, option_str].join(' '), force, ignore_error)
    end

    def run(option, force = false, ignore_error = false)
      if option.class == Hash
        _run_hash option, force, ignore_error
      else
        _run_str option, force, ignore_error
      end
    end

    def which(command)
      _run_command("which #{command}").chomp
    end
  end
end
