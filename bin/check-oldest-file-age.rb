#! /usr/bin/env ruby
#
#   check-oldest-file-age
#
# DESCRIPTION:
#   Finds the oldest file in the given folder and checks it's age
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux, Windows
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   check-oldest-file-age.rb --dir <folder>
#                      --warning <age, in seconds, to warn on>
#                      --critical <age, in seconds, to go CRITICAL on>
# EXIT CODES
#  Failure (2) if given folder doesn't exist
#  Warning (1) if the oldest file older than --warning value but younger than --critical value
#  Failure (2) if the oldest file older than --critical value
#  Success (0) if given folder is empty or oldest file is younger tnan --warning value
# 
# LICENSE:
#   Copyright 2018 Dimitry Karalov (dimitry.karalov@ge.com)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckOldestFile < Sensu::Plugin::Check::CLI
  option :dir,
         description: 'folder to check (full path)',
         short: '-d',
         long: '--dir DIRECTORY',
         required: true

  option :warning_age,
         description: 'The age (in seconds) of the oldest file where WARNING is raised',
         short: '-w AGE',
         long: '--warning AGE',
         required: true

  option :critical_age,
         description: 'The age (in seconds) of the oldest file where CRITICAL is raised',
         short: '-c AGE',
         long: '--critical AGE',
         required: true

    def run_check(type, age)
        to_check = config["#{type}_age".to_sym].to_i
        if to_check > 0 && age >= to_check 
              send(type, "file(s) under #{config[:dir]} are older than #{to_check} seconds")
        end
    end
 
   def run
    if File.exist? config[:dir]
        oldest=Dir.entries(config[:dir]).map { |e| File.join(config[:dir],e)}.select {|f| File.file? f}.sort_by {|f| File.mtime f}.first
        if oldest.nil?
            ok "The directory is empty"
        else
              age = Time.now.to_i - File.mtime(oldest).to_i
              run_check(:critical, age) || run_check(:warning, age) || ok("oldest file is #{age} seconds old")      
        end
    else
        critical "#{config[:dir]} does not exist"
    end
  end

end
