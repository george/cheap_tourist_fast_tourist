# == Background
#   This application is a solution to http://puzzlenode.com/puzzles/3
#
# == Usage
#   international_trade ./cheap_tourist_fast_tourist data/input.txt
#
#   For help use: ./cheap_tourist_fast_tourist -h
#
# == Author
#   George Anderson
#   george@benevolentcode.com

require 'slop'

module CheapTouristFastTourist
  class App
    def initialize(arguments, stdin)
      @arguments = arguments
    end
    
    def run
      parse_options
      verify_flight_data
      process_flight_data
    end
    
    #######
    private
    #######
    
    def display_usage_and_exit(error_message = nil)
      puts "\n#{error_message}\n\n" if error_message
      puts @options
      exit
    end
    
    def file_exists?(filepath)
      filepath && File.exists?(filepath)
    end
    
    # workaround until https://github.com/injekt/slop/pull/15 is accepted and released
    def _parse_options(strict = true)
      @options = Slop.parse!(@arguments, :help => true, :strict => strict) do
        banner "Usage:\n\t./cheap_tourist_fast_tourist [options] data/input.txt\n\nOptions:"
      end
    end
    
    def parse_flight_data
      raw_data = File.new(@flight_data_file).readlines
      pp raw_data
    end

    def parse_options
      _parse_options
    rescue Slop::InvalidOptionError => e
      _parse_options(false)
      display_usage_and_exit(e.message)
    end
    
    def process_flight_data
      parse_flight_data
    end
    
    def verify_flight_data
       @flight_data_file = @arguments.detect { |path| File.extname(path).downcase == '.txt' }
       
       display_usage_and_exit("File containing flight data (#{ @flight_data_file }) does not exist")  unless file_exists?(@flight_data_file)
    end
  end
end