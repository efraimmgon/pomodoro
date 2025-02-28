# Ruby Pomodoro Timer

A feature-rich command-line Pomodoro Timer built with Ruby. This application helps you manage your work sessions using the Pomodoro Technique, a time management method that uses timed intervals of work followed by breaks.

## Features

- [x] 25-minute work sessions
- [x] 5-minute short breaks
- [x] 15-minute long breaks after 4 work sessions
- [x] Interactive CLI interface with color-coded display
- [x] Session progress tracking
- [x] Pause/Resume functionality
- [x] Session reset option
- [ ] Configurable session controls
- [x] Visual and audio notifications for session changes


## Prerequisites

- Ruby 3.2.2 or higher
- Bundler

## Installation

1. Clone this repository:

```bash
git clone https://github.com/efraimmgon/pomodoro.git
cd pomodoro
```

2. Install dependencies:

```bash
bundle install
```

## Usage

Start the Pomodoro Timer:

```bash
ruby pomodoro.rb start
```

Optionally make the `pomodoro.rb` executable and create a symlink to the `pomodoro` command:

```bash
chmod +x pomodoro.rb
ln -s /full/path/to/pomodoro.rb /usr/local/bin/pomodoro
```

### Controls

During a session, you can use the following controls:
- `p` - Pause/Resume the timer
- `r` - Reset the current session
- `q` - Quit the application

## Session Flow

1. Work Session (25 minutes)
2. Short Break (5 minutes)
3. Repeat steps 1-2 three times
4. After 4 work sessions, take a Long Break (15 minutes)
5. The cycle repeats

At the end of each session, you can:
- Start the next session
- Skip the current session
- Quit the application

## Dependencies

- `thor` - Command-line interface
- `tty-prompt` - Interactive command prompts
- `tty-cursor` - Terminal cursor manipulation
- `tty-screen` - Terminal screen size detection
- `colorize` - Terminal output colorization

## License

MIT 