class Array
  def my_uniq
    result = []
    self.each do |el|
      result << el unless result.include?(el)
    end
    result
  end

  def two_sum
    result = []
    (0...self.length-1).each do |i|
      (i+1...self.length).each do |j|
        result << [i, j] if self[i] + self[j] == 0
      end
    end
    result
  end

  def my_transpose
    result = Array.new(self.length) { [] }
    self.each do |row|
      row.each_with_index do |el, index|
        result[index] << el
      end
    end
    result
  end

  def stock_picker
    lowest_price = {index: - 1, price: Float::INFINITY}
    best_pair = [0,0]
    self.each_with_index do |el, index|
      if el < lowest_price[:price]
        lowest_price[:price] = el
        lowest_price[:index] = index
      end
      if el - lowest_price[:price] > self[best_pair[1]] - self[best_pair[0]]
        best_pair[0] = lowest_price[:index]
        best_pair[1] = index
      end
    end
    best_pair
  end
end
