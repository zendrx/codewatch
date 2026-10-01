require "./config.cr"
URL = ENV["URL"]

def show_help : String
  help = <<-STRING
     codewatch --h     shows this help message
     codewatch --config <token> valiidates your id against the server and stored in ~/.config/codewatch never share
     codewatch --watch enables the watch option allows codewatch to start starring
     codewatch profile  ahowcase your profile
    STRING
  return help
end

if ARGV || ARGV.empty
  return "use codewatch -h for help"
end

case ARGV[0]
when "--config"
  watch = Cli.new("{URL}/validate")
  if watch.set_token(ARGV[1])
    puts "user has been validated.."
  end
when "--watch"
  print "\e[?25l"
  Cli.new(URL).watch
when "-h"
  puts show_help
end
