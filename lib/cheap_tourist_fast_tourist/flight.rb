require 'bigdecimal'
require 'big_decimal_extension'
require 'time'

class Flight

  attr_accessor :from, :to, :departure, :arrival, :price, :flight_time

  def initialize(raw_flight_data)
    flight = raw_flight_data.split
    self.from        = flight[0]
    self.to          = flight[1]
    self.departure   = flight[2]
    self.arrival     = flight[3]
    self.price       = BigDecimal(flight[4], 15)
    self.flight_time = calculate_flight_time
  end
  
  def arrival_time
    Time.parse(departure)
  end
  
  def departure_time
    Time.parse(arrival)
  end

  def to_s
    "#{from} #{to} #{departure} #{arrival} #{price.to_s('F').sub(/\.0$/, '.00')}"
  end

  #######
  private
  #######

  # in minutes, not that it matters
  def calculate_flight_time
    ( (Time.parse(departure) - Time.parse(arrival)) / 60.0 ).abs
  end
end
