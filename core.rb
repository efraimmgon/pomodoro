require 'io/console'

class PomodoroTimer
  WORK_DURATION = 25 * 60  # 25 minutes in seconds
  SHORT_BREAK_DURATION = 5 * 60  # 5 minutes in seconds
  LONG_BREAK_DURATION = 15 * 60  # 15 minutes in seconds
  POMODOROS_BEFORE_LONG_BREAK = 4

  def initialize
    @time_remaining = WORK_DURATION
    @running = false
    @completed_pomodoros = 0
    @current_session = :work
    @last_tick = Time.now
  end

  def start
    @running = true
    @last_tick = Time.now
    run_timer_loop
  end

  def pause
    @running = false
  end

  def resume
    @running = true
    @last_tick = Time.now
  end

  def reset
    @time_remaining = current_session_duration
  end

  private

  def run_timer_loop
    loop do
      handle_input
      if @running
        update_timer
        display_timer
      end
      sleep 0.1  # Small delay to prevent high CPU usage
    end
  end

  def handle_input
    if IO.select([STDIN], nil, nil, 0)
      case STDIN.getch.downcase
      when 'p'
        if @running
          pause
        else
          resume
        end
      when 'r' then reset
      when 'q' then exit(0)
      end
    end
  end

  def update_timer
    current_time = Time.now
    elapsed = current_time - @last_tick
    @last_tick = current_time
    
    @time_remaining -= elapsed
    
    if @time_remaining <= 0
      switch_session
    end
  end

  def switch_session
    if @current_session == :work
      @completed_pomodoros += 1
      if @completed_pomodoros % POMODOROS_BEFORE_LONG_BREAK == 0
        @current_session = :long_break
      else
        @current_session = :short_break
      end
    else
      @current_session = :work
    end
    
    notify_session_change
    @running = false  # Pause the timer before handling session end
    handle_session_end
  end

  def handle_session_end
    next_session = @current_session.to_s.gsub('_', ' ').capitalize
    puts "\nNext session: #{next_session}"
    puts "Press:"
    puts "Enter - Start next session"
    puts "s     - Skip next session"
    puts "q     - Quit"
    
    loop do
      case STDIN.getch.downcase
      when "\r", "\n"  # Enter key
        @time_remaining = current_session_duration
        @running = true  # Resume the timer
        @last_tick = Time.now  # Reset the last tick time
        return
      when 's'
        switch_session  # Skip to the following session
        return
      when 'q'
        exit(0)
      end
    end
  end

  def current_session_duration
    case @current_session
      when :work then WORK_DURATION
      when :short_break then SHORT_BREAK_DURATION
      when :long_break then LONG_BREAK_DURATION
    end
  end

  def display_timer
    minutes = (@time_remaining / 60).to_i
    seconds = (@time_remaining % 60).to_i
    system('clear') || system('cls')
    puts "\n=== Pomodoro Timer ==="
    puts "Session: #{@current_session.to_s.gsub('_', ' ').capitalize}"
    puts "Time Remaining: #{format('%02d:%02d', minutes, seconds)}"
    puts "Completed Pomodoros: #{@completed_pomodoros}"
    puts "\nControls:"
    puts "p - pause/resume"
    puts "r - reset current session"
    puts "q - quit"
  end

  def notify_session_change
    puts "\a"  # System bell
    message = case @current_session
                when :work
                  "Time's up! Time for work!"
                when :short_break
                  "Time's up! Time for a short break!"
                when :long_break
                  "Time's up! Time for a long break!"
              end
    puts "\n#{message}"
  end
end
