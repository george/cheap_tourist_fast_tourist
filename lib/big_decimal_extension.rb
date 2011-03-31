require 'bigdecimal'

class BigDecimal
  def inspect
    self.to_s('F').sub(/\.0$/, '.00')
  end
end
