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
# raise group.inspect
      lowest_priced_flight = group.min { |a, b| total_price_of_flight(a) <=> total_price_of_flight(b) }
# raise lowest_priced_flight.inspect
      lowest_price = total_price_of_flight(lowest_priced_flight)
      flights_at_lowest_price = group.find_all{ |legs| total_price_of_flight(legs) == lowest_price }
# raise flights_at_lowest_price.inspect
      if flights_at_lowest_price.size == 1
        flights_at_lowest_price.first
      else
        fastest_flight(flights_at_lowest_price)
      end
      # flights_at_lowest_price.min { |a, b| total_elasped_time_for_flight(a) <=> total_elasped_time_for_flight(b) }
    end
    
    def display_usage_and_exit(error_message = nil)
      puts "\n#{error_message}\n\n" if error_message
      puts @options
      exit
    end

    def fastest_flight(group)
      puts "\n\n\n"
      group.each do |legs|
        puts total_elasped_time_for_flight(legs).divmod(60).join(':')
        puts legs.map(&:inspect).join("\n")
        puts '########################'
      end
      puts "\n\n\n"
      
      
      shortest_flight = group.min { |a, b| total_elasped_time_for_flight(a) <=> total_elasped_time_for_flight(b) }
      shortest_flight_time = total_elasped_time_for_flight(shortest_flight)
# raise (shortest_flight_time).inspect
      flights_at_shortest_time = group.find_all{ |legs| total_elasped_time_for_flight(legs) == shortest_flight_time }
# raise flights_at_shortest_time.inspect
raise shortest_flight_time.divmod(60).join(':').inspect
      if flights_at_shortest_time.size == 1
              flights_at_shortest_time.first
            else
              cheapest_flight(flights_at_shortest_time)
            end
      # flights_at_shortest_time.min { |a, b| total_price_of_flight(a) <=> total_price_of_flight(b) }
    end

    def file_exists?(filepath)
      filepath && File.exists?(filepath)
    end

    def find_flight_sequence(group, flight)
      # raise group.size.inspect
puts "~~~~~~~~~~~~~~~~~~~~~\n\ngroup: #{group.size.inspect} flight: #{flight.inspect}"
      from = flight.to

#       if destination = group.detect{ |f| f.from == from && f.to == 'Z' }
# puts "\tfound a match: #{destination.inspect}"
#         return [group.delete(destination)]
#       end
# raise group.find_all{ |f| f.from == from }.inspect
      group.find_all{ |f| f.from == from }.each do |leg|

        if leg.from == from && leg.to == 'Z'
          # destination = leg
puts "\tfound a destination leg: #{leg.inspect}"
          # return [group.delete(destination)]
          return group.delete(leg)
        end
        
        
        group.delete_if{ |r| r == leg || ( r.to == leg.from && r.from == leg.to ) } # no back-tracking
        
        if other_legs = find_flight_sequence(group, leg)
          # return [other_legs, leg]
          return [leg, other_legs]
        end
      end
    end
    
    def find_flight_sequences(group, flight)
      from = flight.to
      
      flight_group = group.dup
      
      
    end

    def flight_sequences(group)
      return @flight_sequences[group.object_id] if @flight_sequences.has_key?(group.object_id)

      direct, indirect = group.partition { |flight| flight.from == 'A' && flight.to == 'Z' }

      # need direct flight to be (single-element) arrays for Array#min and #max calculations
      # (see #cheapest_flight and #fastest_flight, above)
      direct.collect!{ |f| [f] }

# raise indirect.find_all{|f| f.from == 'A'}.inspect

      @flight_sequences[group.object_id] = direct + indirect.find_all{|f| f.from == 'A'}.collect do |flight|
        [flight] + find_flight_sequences(indirect.dup, flight)
      end
# raise @flight_sequences[group.object_id].inspect
    # rescue Exception => e
    #   raise <<-EOS
    #   
    #   group: #{group.inspect}
    #   
    #   #{e}
    #   
    #   EOS
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
    
    def print_flight(legs)
      legs = legs.sort_by{ |leg| leg.from }
      puts "#{legs.first.departure} #{legs.last.arrival} #{total_price_of_flight(legs).to_s.sub(/\.0$/, '.00')}"
    end

    def process_flight_data
      segregate_flight_groups
      process_flight_groups
    end

    def process_flight_groups
      @flight_groups.each_with_index do |group, idx|
        puts "" unless idx == 0 # print blank line between each group's output
        print_flight(cheapest_flight(flight_sequences(group)))
        print_flight(fastest_flight(flight_sequences(group)))
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
    
    # accepts an (single- or multi-element) array which comprises a "flight" 
    # from 'A' to 'Z' and returns its total price
    def total_price_of_flight(legs)
      legs.inject(0.0){|total, leg| total += leg.price}
    end
    
    # accepts an (single- or multi-element) array which comprises a "flight" 
    # from 'A' to 'Z' and returns its total elapsed time from departure to arrival
    def total_elasped_time_for_flight(legs)
      departure = legs.detect{ |leg| leg.from == 'A' }.departure
      arrival   = legs.detect{ |leg| leg.to   == 'Z' }.arrival
      
      # in minutes
      ( (Time.parse(departure) - Time.parse(arrival)) / 60.0 ).abs
    end

    def verify_flight_data
       @flight_data_file = @arguments.detect { |path| File.extname(path).downcase == '.txt' }

       display_usage_and_exit("File containing flight data (#{ @flight_data_file }) does not exist")  unless file_exists?(@flight_data_file)
    end
  end
end