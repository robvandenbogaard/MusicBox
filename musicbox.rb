#!/usr/bin/env ruby
#
# A simple music box emulator using MIDIator by David Brady
#
# == Authors
#
# * Rob van den Bogaard <robvandenbogaard@gmail.com>
# 
#
# == Copyright
#
# Copyright (c) 2011 Rob van den Bogaard
#
# This code released under the terms of the MIT license.
#

require 'rubygems'
require 'midiator'
 
midi = MIDIator::Interface.new
midi.autodetect_driver

# Instead of letting the user manually connect the midi ports, try to do it automatically (hack hack!)
midi_in = nil
`aconnect -li`.split("\n").each {|line|
  next unless line[0,6] == 'client'
  next unless line.split(':')[1][/[A-Za-z\-]+/] == 'Client-'
  midi_in = line[/[0-9]+/]
  break
}
midi_out = nil
`aconnect -lo`.split("\n").each {|line|
  next unless line[0,6] == 'client'
  next unless line.split(':')[1][/[A-Za-z\-]+/] == 'TiMidity'
  midi_out = line[/[0-9]+/]
  break
}

# If no matching in- and output ports have been found, revert to the manual procedure
if midi_in and midi_out
  `aconnect #{midi_in} #{midi_out}`
else
  midi.instruct_user!
end

include MIDIator::Notes

legend = nil
count = 1
notes = []
song = []
punch = nil
File.open('test.music').each {|line|
  unless legend
    #TODO: make more flexible
    octave = 3
    notes = []
    legend = line.strip.chars.collect {|char|
      if notes.include? char
        octave += 1
        notes = []
      end
      notes << char
      eval(char + octave.to_s)
    }
    notes = []
    next
  end
  if line.strip.empty?
    count += 1
    next
  end
  song << [notes, count, punch] unless notes.empty?
  punch = line
  notes = []
  count = 1
  index = 0
  line.chars.each {|char|
    notes << legend[index] if 'Xx'.include? char
    index += 1
  }
}
song << [notes, count, punch] unless notes.empty?

# Play the song
4.times do
song.each do |line|
  puts line[2]
  (line[1]-1).times do puts "\n" end
  midi.play line[0], 0.25*line[1], 1
end
end

