#!/usr/bin/env ruby
# encoding: UTF-8

module Spotify
  
  def Spotify.do_something(something)
    `osascript -e 'tell application \"Spotify\" to #{something}'`.gsub("\n", "")
  end
  
  def Spotify.get_something(something)
    `osascript -e 'tell application \"Spotify\"\n\t#{something}\nend tell\n'`.gsub("\n", "")
  end
  
  def Spotify.playing?()
    Spotify.get_something("player state") == "playing"
  end
  
  def Spotify.paused?()
    Spotify.get_something("player state") == "paused"
  end
  
  def Spotify.stopped?()
    Spotify.get_something("player state") == "stopped"
  end
  
  def Spotify.play()
    Spotify.do_something("play")
  end
  
  def Spotify.pause()
    Spotify.do_something("pause")
  end

  def Spotify.toggle_playing()
    Spotify.do_something("playpause")
  end
  
  def Spotify.next()
    Spotify.do_something("play next track")
  end
  
  def Spotify.previous()
    Spotify.do_something("play previous track")
  end
  
  def Spotify.song_position()
    current = Spotify.get_something("player position").to_i
    total = Spotify.get_something("duration of current track").to_i
    
    puts "#{current}/#{total}"
  end
  
  def Spotify.now_playing()
    name   = Spotify.get_something("name of current track")
    artist = Spotify.get_something("artist of current track")
    
    return name, artist
  end
  
end

def print_help()
  puts "\nusage: spotty [args]"
  puts "A command line interface to Spotify on Mac OS X."
  puts "Available commands:"
  puts "play - Play a song if it's paused or stopped.\n"
  puts "pause - Pause a song if it's playing.\n"
  puts "toggleplaying - Toggle the song between playing and paused."
  puts "Aliases: playpause, tp, pp\n"
  puts "next - Skip the currently playing song\n"
  puts "previous - Restart the current song or go back to the previously playing song.\n"
  puts "Aliases: prev\n"
  puts "playing? - Is Spotify playing any music right now?"
  puts "Aliases: p?\n"
  puts "nowplaying - Print the currently playing song."
  puts "Format: <song name> by <song artist>"
  puts "Aliases: np\n"
  puts "help - Print this help page."
  puts "\n\nThank you for using spotty!"
end

ARGV.each do |arg|
  case arg
  when "play"
    Spotify.play
  when "pause"
    Spotify.pause
  when "toggleplaying", "playpause", "tp", "pp"
    Spotify.toggle_playing
  when "next"
    Spotify.next
  when "previous", "prev"
    Spotify.previous
  when "playing?", "p?"
    puts "Spotify is playing right now." if Spotify.playing?
    puts "Nope, Spotify ain't playing." if not Spotify.playing?
  when "songposition", "sp"
    Spotify.song_position
  when "nowplaying", "np"
    name, artist = Spotify.now_playing
    puts "Currently playing " + name + " by " + artist
  else
    print_help
  end
end