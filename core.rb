require 'io/console'
require 'tty-prompt'
require 'tty-cursor'
require 'tty-screen'
require 'colorize'
require 'json'
require 'date'

class PomodoroTimer
  WORK_DURATION = 25 * 60 # 25 minutes in seconds
  SHORT_BREAK_DURATION = 5 * 60  # 5 minutes in seconds
  LONG_BREAK_DURATION = 15 * 60  # 15 minutes in seconds
  POMODOROS_BEFORE_LONG_BREAK = 4
  STATS_FILE = 'pomodoro_stats.json'

  def initialize
    @prompt = TTY::Prompt.new
    @cursor = TTY::Cursor
    @time_remaining = WORK_DURATION
    @running = false
    @daily_stats = load_daily_stats
    @completed_pomodoros = completed_pomodoros_today
    @current_session = :work
    @last_tick = Time.now
  end

  # Starts the Pomodoro timer and begins the main timer loop
  def start
    @running = true
    @last_tick = Time.now
    run_timer_loop
  end

  # Pauses the current timer session
  def pause
    @running = false
  end

  # Resumes the paused timer session
  def resume
    @running = true
    @last_tick = Time.now
  end

  # Resets the current session timer to its original duration
  def reset
    @time_remaining = current_session_duration
  end

  private

  # Main timer loop that handles user input and updates the display
  # Runs continuously until the program is terminated
  def run_timer_loop
    loop do
      handle_input
      if @running
        update_timer
        display_timer
      end
      sleep 0.1 # Small delay to prevent high CPU usage
    end
  end

  # Handles keyboard input for timer controls
  def handle_input
    return unless IO.select([STDIN], nil, nil, 0)

    case STDIN.getch.downcase
    when 'p'
      if @running
        pause
      else
        resume
      end
    when 'r' then reset
    when 'q' then exit(0)
    when 's' then @show_stats = !@show_stats
    end
  end

  # Updates the remaining time based on elapsed time since last tick
  # Switches to next session when timer reaches zero
  def update_timer
    current_time = Time.now
    elapsed = current_time - @last_tick
    @last_tick = current_time

    @time_remaining -= elapsed

    return unless @time_remaining <= 0

    switch_session
  end

  # Switches between work and break sessions
  # Updates statistics and handles session transitions
  def switch_session
    if @current_session == :work
      @completed_pomodoros += 1
      update_daily_stats if @current_session == :work
      @current_session = if @completed_pomodoros % POMODOROS_BEFORE_LONG_BREAK == 0
                           :long_break
                         else
                           :short_break
                         end
    else
      @current_session = :work
    end

    notify_session_change
    @running = false
    handle_session_end
  end

  # Handles the end of a session by prompting user for next action
  def handle_session_end
    next_session = @current_session.to_s.gsub('_', ' ').capitalize
    puts "\nNext session: #{next_session}"

    choice = @prompt.select('Choose your action:', {
                              'Start next session' => :start,
                              'Skip session' => :skip,
                              'Quit' => :quit
                            })

    case choice
    when :start
      @time_remaining = current_session_duration
      @running = true
      @last_tick = Time.now
    when :skip
      switch_session
    when :quit
      exit(0)
    end
  end

  # Returns the duration for the current session type
  # @return [Integer] duration in seconds
  def current_session_duration
    case @current_session
    when :work then WORK_DURATION
    when :short_break then SHORT_BREAK_DURATION
    when :long_break then LONG_BREAK_DURATION
    end
  end

  def completed_pomodoros_today
    @daily_stats[Date.today.to_s] or 0
  end

  # Displays the timer interface including countdown, session info, and controls
  def display_timer
    minutes = (@time_remaining / 60).to_i
    seconds = (@time_remaining % 60).to_i

    print @cursor.clear_screen
    print @cursor.move_to(0, 0)

    TTY::Screen.width

    puts "\n#{center_text('=== Pomodoro Timer ===').colorize(color: :red, mode: :bold)}"
    puts center_text("Session: #{@current_session.to_s.gsub('_', ' ').capitalize}")
    puts "\n"
    puts center_text('╔══════════════╗').colorize(:light_yellow)
    puts center_text("║ #{format('%02d:%02d', minutes, seconds)} ║").colorize(:yellow)
    puts center_text('╚══════════════╝').colorize(:light_yellow)
    puts "\n"
    puts center_text("Completed Pomodoros: #{@completed_pomodoros}")
    puts "\n#{center_text('Controls:').colorize(color: :light_red, mode: :bold)}"
    puts center_text('p - pause/resume')
    puts center_text('r - reset current session')
    puts center_text('q - quit')
    puts center_text('s - show statistics')

    display_stats if @show_stats
  end

  # Sends a system notification when switching between sessions
  def notify_session_change
    message = case @current_session
              when :work
                'Time for work!'
              when :short_break
                'Time for a short break!'
              when :long_break
                'Time for a long break!'
              end
    system("say \"#{message}\"")
    puts "\n#{message}"
  end

  # Centers text in the terminal window
  # @param text [String] the text to center
  # @return [String] the centered text with appropriate padding
  def center_text(text)
    padding = [(TTY::Screen.width - text.length) / 2, 0].max
    ' ' * padding + text
  end

  # Loads daily statistics from the JSON file
  # @return [Hash] daily statistics with dates as keys and completed sessions as values
  def load_daily_stats
    return {} unless File.exist?(STATS_FILE)

    JSON.parse(File.read(STATS_FILE))
  rescue JSON::ParserError
    {}
  end

  # Updates the statistics for the current day
  def update_daily_stats
    today = Date.today.to_s
    @daily_stats[today] ||= 0
    @daily_stats[today] += 1
    save_daily_stats
  end

  # Saves the daily statistics to the JSON file
  def save_daily_stats
    File.write(STATS_FILE, JSON.pretty_generate(@daily_stats))
  end

  # Displays the statistics of completed sessions by date
  def display_stats
    puts "\n#{center_text('=== Statistics ===').colorize(color: :cyan, mode: :bold)}"
    if @daily_stats.empty?
      puts center_text('No stats yet')
    else
      @daily_stats.sort.reverse.each do |date, count|
        puts center_text("#{date}: #{count} sessions")
      end
    end
  end
end
