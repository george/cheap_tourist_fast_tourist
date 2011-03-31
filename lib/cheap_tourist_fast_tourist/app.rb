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

require 'bigdecimal'
# require 'flight'
require 'slop'
require 'time'

module CheapTouristFastTourist
  class App
    def initialize(arguments, stdin)
      @arguments = arguments
      @flight_groups = []
      @flight_sequences = {}
    end

    def run
      parse_options
      verify_flight_data
      process_flight_data
    end

    #######
    private
    #######

    def cheapest_flight(group)
      lowest_priced_flight = flight_sequences(group).min { |a, b| total_price_of_flight(a) <=> total_price_of_flight(b) }
      lowest_price = total_price_of_flight(lowest_priced_flight)
raise group.inspect
      flights_at_lowest_price = group.find_all{ |legs| total_price_of_flight(legs) == lowest_price }
raise flights_at_lowest_price.inspect
      if flights_at_lowest_price.size == 1
        puts flights_at_lowest_price.first + "\n\n"
      else
        # puts fastest_flight(flights_at_lowest_price)
      end
    end
    
    # accepts an (single- or multi-element) array which comprises a "flight" 
    # from 'A' to 'Z' and returns its total price
    def total_price_of_flight(legs)
      legs.inject(0.0){|total, leg| total += leg.price}
rescue Exception => e
  raise <<-EOS
  
  legs: #{legs.inspect}
  
  
  #{e}
  
  EOS
    end

    def display_usage_and_exit(error_message = nil)
      puts "\n#{error_message}\n\n" if error_message
      puts @options
      exit
    end

    def fastest_flight(group)
      flight_sequences(group)
    end

    def file_exists?(filepath)
      filepath && File.exists?(filepath)
    end

    def find_flight_sequence(group, flight)
      from = flight.to

      if destination = group.detect{ |f| f.from == from && f.to == 'Z' }
        return [group.delete(destination)]
      end

      group.find_all{ |f| f.from == from }.each do |leg|
        group.delete_if{ |r| r == leg || ( r.to == leg.from && r.from == leg.to ) } # no back-tracking

        if other_legs = find_flight_sequence(group, leg)
          return [other_legs, leg]
        end
      end
    end

    def flight_sequences(group)
      return @flight_sequences[group.object_id] if @flight_sequences.has_key?(group.object_id)

      direct, indirect = group.partition { |flight| flight.from == 'A' && flight.to == 'Z' }

      # need direct flight to be (single-element) arrays for Array#min and #max calculations
      # (see #cheapest_flight and #fastest_flight, above)
      direct.collect!{ |f| [f] }

      @flight_sequences[group.object_id] = direct + indirect.find_all{|f| f.from == 'A'}.collect do |flight|
        [flight] + find_flight_sequence(indirect.dup, flight)
      end
      
      raise @flight_sequences[group.object_id].inspect
    end

    # workaround until https://github.com/injekt/slop/pull/15 is accepted and released
    def _parse_options(strict = true)
      @options = Slop.parse!(@arguments, :help => true, :strict => strict) do
        banner "Usage:\n\t./cheap_tourist_fast_tourist [options] data/input.txt\n\nOptions:"
      end
    end

    def parse_options
      _parse_options
    rescue Slop::InvalidOptionError => e
      _parse_options(false)
      display_usage_and_exit(e.message)
    end

    def process_flight_data
      segregate_flight_groups
      process_flight_groups
    end

    def process_flight_groups
# raise @flight_groups.inspect
      @flight_groups.each_with_index do |group, idx|
# raise group.inspect
        puts "" unless idx == 0 # print blank line between each group's output
        puts cheapest_flight(group)
        puts fastest_flight(group)
      end
    end

    def raw_flight_data
      @raw_flight_data ||= File.new(@flight_data_file).readlines
    end

    def segregate_flight_groups
      _flight_groups = []

      raw_flight_data.each_with_index do |line, idx|
        next if idx == 0 # ignore the number of test cases

        if /^\d+$/ =~ line.chomp!
          flights = Integer(line)
          _flight_groups << ( (idx + 1)..(idx + flights) ).to_a
        end
      end

      @flight_groups = _flight_groups.collect do |group|
        group.collect do |flight_idx|
          Flight.new(raw_flight_data.at(flight_idx))
        end
      end
    end

    def verify_flight_data
       @flight_data_file = @arguments.detect { |path| File.extname(path).downcase == '.txt' }

       display_usage_and_exit("File containing flight data (#{ @flight_data_file }) does not exist")  unless file_exists?(@flight_data_file)
    end
  end
end