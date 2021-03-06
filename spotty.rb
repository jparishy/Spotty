#!/usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'meta-spotify'
require 'colorize'

module Spotify
  
  #
  # The following two methods interface with Spotify's AppleScript integration.
  # You can find the documentation on the exported AppleScript functions
  # by loading AppleScript Editor, opening the Library window, then adding the
  # Spotify.app file to the list. This will show you the library functions 
  # for Spotify. All the information used to create this program was found
  # through this documentation.
  #
  
  #
  # Spotify.do_something(something)
  #
  # Tell Spotify to perform an operation. Additionally strips off the newline
  # character at the end of the result.
  #
  # For Example:
  # Spotify.do_something("play")
  #
  # ...generates...
  #
  # tell application "Spotify" to #{something}
  #
  # ...will result in Spotify playing the current song.
  #
  def Spotify.do_something(something)
    `osascript -e 'tell application \"Spotify\" to #{something}'`.gsub("\n", "")
  end
  
  #
  # Spotify.get_something(something)
  #
  # Sets up a string that consists of AppleScript that tells Spotify to
  # return the value for the query 'something'. Additionally strips off the newline
  # character at the end of the result.
  #
  # For Example:
  # Spotify.get_something("player state")
  #
  # ...generates...
  #
  # tell application "Spotify"
  #   player state
  # end tell
  #
  # ...which might return...
  #
  # "paused"
  #
  def Spotify.get_something(something)
    `osascript -e 'tell application \"Spotify\"\n\t#{something}\nend tell\n'`.gsub("\n", "")
  end
  
  #
  # Spotify.playing?
  #
  # Is the Spotify music player currently playing a song?
  #
  def Spotify.playing?()
    Spotify.get_something("player state") == "playing"
  end
  
  #
  # Spotify.paused?
  #
  # Is the Spotify music player paused?
  #
  def Spotify.paused?()
    Spotify.get_something("player state") == "paused"
  end
  
  #
  # Spotify.stopped?
  #
  # Is the Spotify music player stopped?
  #
  def Spotify.stopped?()
    Spotify.get_something("player state") == "stopped"
  end
  
  #
  # Spotify.play
  #
  # Play a currently paused song. No action taken if
  # no song is queued up, ie. Spotify was just started.
  #
  def Spotify.play()
    Spotify.do_something("play")
  end
  
  #
  # Spotify.pause
  #
  # Pause the currently playing song.
  #
  def Spotify.pause()
    Spotify.do_something("pause")
  end

  #
  # Spotify.toggle_playing
  #
  # If the song is paused, play it.
  # If the song is playing, pause it.
  #
  def Spotify.toggle_playing()
    Spotify.do_something("playpause")
  end
  
  #
  # Spotify.next
  #
  # Skip the currently playing track and play the next one.
  #
  def Spotify.next()
    Spotify.do_something("play next track")
  end
  
  #
  # Spotify.previous
  #
  # Play the previous song, or restart the current one if the
  # playback position is after a certain threshold. This is
  # normal media player behavior and part of Spotify.
  #
  def Spotify.previous()
    Spotify.do_something("play previous track")
  end
  
  #
  # Spotify.song_position
  #
  # Prints out the playback time of the current song and the duration
  # in the format "<current time>/<duration>"
  #
  def Spotify.song_position()
    current = Spotify.get_something("player position").to_i
    total = Spotify.get_something("duration of current track").to_i
    
    puts "#{current}/#{total}"
  end
  
  #
  # Spotify.now_playing
  #
  # Returns an array containing the name of the currently playing song
  # and the artist of the song
  #
  def Spotify.now_playing()
    name   = Spotify.get_something("name of current track")
    artist = Spotify.get_something("artist of current track")
    
    return name, artist
  end
  
  #
  # Spotify.search
  #
  # Search Spotify for music.
  #
  # Performs a search and saves at most 5 (for now) results from each category
  # to a temporary file (~/.spotty.ss) for later recollection in Spotify.play_saved_item.
  #
  # This allows the user to search and play songs from the command line.
  #
  def Spotify.search(term, print_results = true)
    
    tracks = MetaSpotify::Track.search(term)[:tracks]
    artists = MetaSpotify::Artist.search(term)[:artists]
    albums = MetaSpotify::Album.search(term)[:albums]
    
    tracks = tracks.take 5 if tracks
    artists = artists.take 5 if artists
    albums = albums.take 5 if albums
    
    play_index = 0
    
    saved_search_file = File.open(File.expand_path("~/.spotty.ss"), File::CREAT|File::TRUNC|File::WRONLY)
    
    tracks.each do |track|
      puts "[##{play_index}] Track: #{track.name.blue} by #{track.artists.first.name.red}" if print_results
      saved_search_file.write "[#{play_index}] " + track.uri + "\n" if saved_search_file
      play_index += 1
    end
    
    artists.each do |artist|
      puts "[##{play_index}] Artist: #{artist.name.red}" if print_results
      saved_search_file.write "[#{play_index}] " + artist.uri + "\n" if saved_search_file
      play_index += 1
    end
    
    albums.each do |album|
      puts "[##{play_index}] Album: #{album.name.blue} by #{album.artists.first.name.red}" if print_results
      saved_search_file.write "[#{play_index}] " + album.uri + "\n" if saved_search_file
      play_index += 1
    end
    
    saved_search_file.close
  end
  
  def Spotify.uri_type(link)
    link.split(":")[1]
  end
  
  def Spotify.play_saved_item(item_number)
    saved_search_file = File.open(File.expand_path("~/.spotty.ss"), File::RDONLY)
    if saved_search_file
      contents = saved_search_file.read
      uri = contents.split("\n")[item_number].split(" ")[1]
      
      case Spotify.uri_type(uri)
      when "track"
        Spotify.do_something "play track \"#{uri}\""
        
        name, artist = Spotify.now_playing
        puts "Currently playing " + name.blue + " by " + artist.red
      when "artist"
        puts "Queing songs from saved artist."
      when "album"
        puts "Queing saved album."
      end
      
      saved_search_file.close
    end
  end
  
end

#
# print_help
#
# Print out some information for when the program is run with the 'help'
# option or the option isn't recognized.
#
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

#
# Let's go ahead and loop through all of the passed arguments and
# perform each operation sequentially. This can be fancied up to support
# arguments in the future.
#

case ARGV[0]
when "play"
  if ARGV[1] && ARGV[1] == "-s"
    Spotify.search(ARGV.drop(2).join(" "), false)
    Spotify.play_saved_item(0)
  else
    Spotify.play
  end
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
  puts "Currently playing " + name.blue + " by " + artist.red
when "search", "s"
  Spotify.search(ARGV.drop(1).join(" "), true) if ARGV[0] == "search"
when "playsaved", "ps"
  Spotify.play_saved_item(ARGV[1].to_i)
else
  print_help
end