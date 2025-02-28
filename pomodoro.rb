#!/usr/bin/env ruby
require_relative 'core'

if ARGV.empty?
  puts "\n"
  puts "Usage: pomodoro [command]"
  puts "Commands:"
  puts "  start   - Start a new Pomodoro session"
  puts "  help    - Show this help message"
  puts "\n"
  exit
end

case ARGV[0].downcase
when 'start'
  timer = PomodoroTimer.new
  timer.start
when 'help'
  puts "\n"
  puts "Pomodoro Timer Commands:"
  puts "  start   - Start a new Pomodoro session"
  puts "  help    - Show this help message"
  puts "\nWhile running:"
  puts "  p - pause/resume"
  puts "  r - reset current session"
  puts "  q - quit"
  puts "\n"
else
  puts "\n"
  puts "Unknown command. Use 'pomodoro help' for usage information."
  puts "\n"
end 