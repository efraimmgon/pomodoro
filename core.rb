require 'io/console'
require 'tty-prompt'
require 'tty-cursor'
require 'tty-screen'
require 'colorize'
require 'json'
require 'date'

class PomodoroTimer
  WORK_DURATION = 25 * 60  # 25 minutes in seconds
  SHORT_BREAK_DURATION = 5 * 60  # 5 minutes in seconds
  LONG_BREAK_DURATION = 15 * 60  # 15 minutes in seconds
  POMODOROS_BEFORE_LONG_BREAK = 4
  STATS_FILE = 'pomodoro_stats.json'

  def initialize
    @prompt = TTY::Prompt.new
    @cursor = TTY::Cursor
    @time_remaining = WORK_DURATION
    @running = false
    @completed_pomodoros = 0
    @current_session = :work
    @last_tick = Time.now
    @daily_stats = load_daily_stats
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
      when 's' then @show_stats = !@show_stats
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
      update_daily_stats if @current_session == :work
      if @completed_pomodoros % POMODOROS_BEFORE_LONG_BREAK == 0
        @current_session = :long_break
      else
        @current_session = :short_break
      end
    else
      @current_session = :work
    end
    
    notify_session_change
    @running = false
    handle_session_end
  end

  def handle_session_end
    next_session = @current_session.to_s.gsub('_', ' ').capitalize
    puts "\nNext session: #{next_session}"
    
    choice = @prompt.select("Choose your action:", {
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
    
    print @cursor.clear_screen
    print @cursor.move_to(0, 0)
    
    width = TTY::Screen.width
    
    puts "\n#{center_text('=== Pomodoro Timer ===').colorize(color: :red, mode: :bold)}"
    puts center_text("Session: #{@current_session.to_s.gsub('_', ' ').capitalize}")
    puts "\n"
    puts center_text("╔══════════════╗").colorize(:light_yellow)
    puts center_text("║ #{format('%02d:%02d', minutes, seconds)} ║").colorize(:yellow)
    puts center_text("╚══════════════╝").colorize(:light_yellow)
    puts "\n"
    puts center_text("Completed Pomodoros: #{@completed_pomodoros}")
    puts center_text("Today's Completed Sessions: #{@daily_stats[Date.today.to_s] || 0}")
    puts "\n#{center_text('Controls:').colorize(color: :light_red, mode: :bold)}"
    puts center_text('p - pause/resume')
    puts center_text('r - reset current session')
    puts center_text('q - quit')
    puts center_text('s - show statistics')

    display_stats if @show_stats
  end

  def notify_session_change
    message = case @current_session
                when :work
                  "Time for work!"
                when :short_break
                  "Time for a short break!"
                when :long_break
                  "Time for a long break!"
              end
    system("say \"#{message}\"")
    puts "\n#{message}"
  end

  def center_text(text)
    padding = [(TTY::Screen.width - text.length) / 2, 0].max
    " " * padding + text
  end

  def load_daily_stats
    return {} unless File.exist?(STATS_FILE)
    JSON.parse(File.read(STATS_FILE))
  rescue JSON::ParserError
    {}
  end

  def update_daily_stats
    today = Date.today.to_s
    @daily_stats[today] ||= 0
    @daily_stats[today] += 1
    save_daily_stats
  end

  def save_daily_stats
    File.write(STATS_FILE, JSON.pretty_generate(@daily_stats))
  end

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
