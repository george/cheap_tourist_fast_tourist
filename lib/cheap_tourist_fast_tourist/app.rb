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
      group = remove_invalid_flights(group.dup)
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

    def determine_flight_sequences(flights)
      originating_flights = flights.find_all{|f| f.from == 'A' }

      originating_flights.collect do |originating_flight|
        if originating_flight.to == 'Z'
          [originating_flight]
        else
          determine_individual_flight_sequences((flights.dup - originating_flights), originating_flight).collect do |tail_sequence|
            tail_sequence.unshift(originating_flight)
          end
        end
      end
    end

    def determine_individual_flight_sequences(flights, departing_flight = nil)
      departing = departing_flight ? departing_flight.to : 'A'

      originating_flights = flights.find_all do |f|
        f.from == departing &&
        (f.to != (departing_flight && departing)) # &&
        # (departing_flight.nil? || departing_flight.arrival_time >= f.departure_time)
      end

      # iterate through originating_flights, collecting their full routes
      originating_flights.collect do |originating_flight|
        if originating_flight.to == 'Z'
          [originating_flight]
        else
          domain_of_flights = flights.dup.delete_if{ |f| f == originating_flight || (f.to == originating_flight.from && f.from == originating_flight.to) }

          if domain_of_flights.size == 1
            return [originating_flight, domain_of_flights.first]
          else
             determine_individual_flight_sequences(domain_of_flights, originating_flight).unshift(originating_flight).flatten
          end
        end
      end
    end

    def display_usage_and_exit(error_message = nil)
      puts "\n#{error_message}\n\n" if error_message
      puts @options
      exit
    end

    def fastest_flight(group)
      group = remove_invalid_flights(group.dup)
      # puts "\n\n\nFASTEST FLIGHT\n"
      # group.each do |legs|
      #   puts total_elasped_time_for_flight(legs).divmod(60).join(':')
      #   puts legs.map(&:inspect).join("\n")
      #   puts '########################'
      # end
      # puts "\n\n\n"


      shortest_flight = group.min { |a, b| total_elasped_time_for_flight(a) <=> total_elasped_time_for_flight(b) }
      shortest_flight_time = total_elasped_time_for_flight(shortest_flight)
# raise (shortest_flight_time).inspect
      flights_at_shortest_time = group.find_all{ |legs| total_elasped_time_for_flight(legs) == shortest_flight_time }
# raise flights_at_shortest_time.inspect
# raise shortest_flight_time.divmod(60).join(':').inspect
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

    def flight_sequences(group)
      return @flight_sequences[group.object_id] if @flight_sequences.has_key?(group.object_id)

      direct, indirect = group.partition { |flight| flight.from == 'A' && flight.to == 'Z' }

      # need direct flight to be (single-element) arrays for Array#min and #max calculations
      # (see #cheapest_flight and #fastest_flight, above)
      direct.collect!{ |f| [f] }

      @flight_sequences[group.object_id] = direct + determine_flight_sequences(indirect).inject([]){ |acc, ary| acc + ary}
      # raise @flight_sequences[group.object_id].inspect
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

    # remove flights which have a leg that arrives after its connecting flight departs
    def remove_invalid_flights(flight_sequences)
      valid = flight_sequences.find_all do |flight_sequence|
        flight_sequence.all? do |leg|
          if leg.from == 'A' && leg.to == 'Z'
            true
          elsif leg.to == 'Z'
            true
          else
            connections = flight_sequence.find_all{|f| leg.to == f.from}
            if connections.size > 1
              raise <<-EOS

              leg: #{leg.inspect}

              connections: #{connections.inspect}

              EOS

            elsif false && leg.departure=="15:45" && leg.flight_time==60.0 && leg.from=="C"  && leg.price==50.00 && leg.to=="B" && leg.arrival=="16:45"
              raise <<-EOS

              leg: #{leg.inspect}

              connection: #{connections.first.inspect}

              leg.arrival_time: #{leg.arrival_time.inspect}

              connection.departure_time: #{connections.first.departure_time.inspect}

              (leg.arrival_time <= connection.departure_time): #{(leg.arrival_time <= connections.first.departure_time).inspect}
              (leg.arrival <= connection.departure): #{(leg.arrival <= connections.first.departure).inspect}
              EOS
            else
              connection = connections.first
            end
# puts "\n\n#{leg.arrival_time} > #{connection.departure_time} ??? #{(leg.arrival_time > connection.departure_time).inspect} :: #{(leg.arrival_time <=> connection.departure_time).inspect}\n\n"
            # connection && (leg.arrival_time <= connection.departure_time)
            connection && (leg.arrival <= connection.departure)
          end
        end
      end
      valid
#       raise <<-EOS
#
# #{valid.inspect}
#
#
# #{flight_sequences.inspect}
#
#       EOS
    end

    def process_flight_groups
      @flight_groups.each_with_index do |group, idx|
        puts "" unless idx == 0 # print blank line between each group's output
        print_flight( cheapest_flight( flight_sequences( group ) ) )
        print_flight( fastest_flight(  flight_sequences( group ) ) )
      end
    end

    def raw_flight_data
      @raw_flight_data ||= File.new(@flight_data_file).readlines
    end

    def segregate_flight_groups
      _flight_groups = []

      raw_flight_data.each_with_index do |line, idx|
        next if idx == 0 # ignore the number of test cases

        # for ease of debugging
          next if line == "\n"
          next if line =~ /^# /

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
    rescue Exception => e
      raise <<-EOS

      ERROR in total_elasped_time_for_flight

      legs:
      #{legs.inspect}

      ----------------------------------------------

      #{e}

      EOS
    end

    def verify_flight_data
       @flight_data_file = @arguments.detect { |path| File.extname(path).downcase == '.txt' }

       display_usage_and_exit("File containing flight data (#{ @flight_data_file }) does not exist")  unless file_exists?(@flight_data_file)
    end
  end
end