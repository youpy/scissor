# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

include FileUtils

describe Scissor::Command do
  before do
  end

  after do
  end

  it "should set work_dir" do
    command = Scissor::Command.new({:command => 'ls'})
    command.work_dir.should eql(Pathname.new(Dir.tmpdir + "/scissor-work-" + $$.to_s))
  end

  it "should set command variable" do
    command = Scissor::Command.new({:command => 'ls'})
    command.command.should eql('/bin/ls')
  end

  describe "#_run_command" do
    before do
      @ls_err = /ls: xxx.*: No such file or directory/
      @read_file = lambda {|file|
        f = open file
        begin
          buff = f.readlines.join('')
        ensure
          f.close
          File.unlink file
        end
        buff
      }
    end

    after do
    end

    it "should clean up work_dir" do
      command = Scissor::Command.new(:command => 'ls')
      command._run_command('ls')
      command.work_dir.should_not be_exist
    end

    it "should return command result" do
      command = Scissor::Command.new(:command => 'ls')
      command._run_command('ls').should include('Rakefile')
    end

    it "should save work_dir" do
      tmp_dir = "#{Dir.tmpdir}/scissor-command-test"
      command = Scissor::Command.new(:command => 'ls', :work_dir => tmp_dir, :options => { :save_work_dir => true})
      command._run_command('ls')
      command.work_dir.should be_exist
    end

    it "should log command error when logger.lebel == DEBUG" do
      _logger = Scissor.logger
      _level = Scissor.logger.level

      file = 'log.log'
      Scissor.logger = Logger.new file
      Scissor.logger.level = Logger::DEBUG
      command = Scissor::Command.new(:command => 'ls')
      lambda {
        command._run_command('ls xxx')
      }.should raise_error(Scissor::Command::CommandFailed)
      @read_file.call(file).should match(@ls_err)
      
      Scissor.logger = _logger
      Scissor.logger.level = _level
    end

    it "should not log command error when logger.level is default(INFO)" do
      _logger = Scissor.logger
      _level = Scissor.logger.level

      file = 'log.log'
      Scissor.logger = Logger.new file
      Scissor.logger.level = Logger::INFO
      command = Scissor::Command.new(:command => 'ls')
      lambda {
        command._run_command('ls xxx')
      }.should raise_error(Scissor::Command::CommandFailed)
      @read_file.call(file).should_not match(@ls_err)
      
      Scissor.logger = _logger
      Scissor.logger.level = _level
    end

    it "should return error output as result when force = true" do
      _logger = Scissor.logger
      _level = Scissor.logger.level

      file = 'log.log'
      Scissor.logger = Logger.new file
      Scissor.logger.level = Logger::DEBUG
      result = ''
      command = Scissor::Command.new(:command => 'ls')
      lambda {
        result = command._run_command('ls xxx', true)
      }.should_not raise_error(Scissor::Command::CommandFailed)
      @read_file.call(file).should match(@ls_err)
      result.should match(@ls_err)
      
      Scissor.logger = _logger
      Scissor.logger.level = _level
    end
  end

  it "should return command result by #_run_hash" do
    command = Scissor::Command.new({:command => 'ruby'})
    command._run_hash({'-e' => '"print 123"'}).should include('123')
  end

  it "should return command result by #_run_str" do
    command = Scissor::Command.new({:command => 'ruby'})
    command._run_str('-e "print 123"').should include('123')
  end

  it "shoud return commnad result by #run" do
    command_hash = Scissor::Command.new({:command => 'ruby'})
    command_hash.run({'-e' => '"print 123"'}).should include('123')
    
    command_str = Scissor::Command.new({:command => 'ruby'})
    command_str.run('-e "print 123"').should include('123')
  end

  it "should return command path by #which" do
    command = Scissor::Command.new(:command => 'ls')
    command.which('ls').should include('/bin/ls')
  end
end
