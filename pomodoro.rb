#!/usr/bin/env ruby
require 'thor'
require_relative 'core'

class PomodoroCLI < Thor
  desc "start", "Start a new Pomodoro session"
  def start
    timer = PomodoroTimer.new
    timer.start
  end

  desc "version", "Show version number"
  def version
    puts "Pomodoro Timer v1.0.0"
  end
end

PomodoroCLI.start(ARGV) 