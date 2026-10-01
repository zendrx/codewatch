require "http/client"
require "json"

class Cli
  def initialize(url)
    @url = url
  end

  def set_token(token) : Bool
    response = HTTP::Client.get(url)
    if response.status_code == 200
      data = JSON.parse(response.body)
      message = data["message"]
      if message == "user exists"
        File.open("~/.config/codewatch", "a") do |f|
          f.puts(token)
        end
        true
      else
        false
      end
    end
  end

  def watch
    poll_intervals = 10
    coding = coding?
    total_seconds = 0i64
    last_state = nil
    last_report = 10.minutes
    sync = Time.monotonic
    loop do
      if coding != last_state
        print "\e[k"
        puts coding ? "coding detected.." : "paused no editor is  running"
        last_state = coding
      end
      total_seconds += poll_intervals if coding
      data = format_duration(total_seconds)
      print "\r\e[k #{data}"
      sleep poll_intervals.seconds
      File.open("~/.config/codewatch/secs", "a") do |file|
        file.puts(total_seconds)
      end
      if (Time.monotonic - sync) >= last_report
        send_to_server
      end
    end
  end

  def format_duration(sec : Int64) : String
    h = sec // 3600
    m = (sec % 3600) // 60
    s = sec % 60
    format("%02dh %02dm, %02s", h, m, s)
  end

  def coding? : Bool
    apps = %w[code code-oss zed alacritty kitty ghostty gnome-terminal- xfce4-termnal nvim helix]
    Dir.each_child("/proc") do |entry|
      next unless entry.matches?(/^\d+$/)
      begin
        name = File.read("/proc/#{entry}/comm").chomp
      rescue
        next
      end
      return true if apps.includes?(name)
    end
    false
  end

  def send_to_server
    body = [
      {
        seconds: File.read("~/.config/codewatch/secs"),
        user:    File.read("~/.config/codewatch/auth"),
      },
    ].to_json
    HTTP::Client.get(url, body: body)
  end
end
