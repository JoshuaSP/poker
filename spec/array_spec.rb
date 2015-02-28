require 'w1_array'
require 'rspec'

RSpec.describe Array do
  describe '#my_uniq' do

    context "when given an array with all unique values" do
      it "returns the same array" do
        expect([1,2,32].my_uniq).to eq([1,2,32])
      end
    end

    context "when given an array with duplicates" do
      it "removes duplicates" do
        expect([1,2,32,2,32].my_uniq).to eq([1,2,32])
      end
    end
  end

  describe '#two_sum' do

    context "when no pairs sum to zero" do
      it "returns empty array" do
        expect([1,2,32].two_sum).to eq([])
      end
    end

    context "when pairs sum to zero" do
      it "returns array of pairs in order" do
        expect([-1, 0, 2, -2, 1].two_sum).to eq([[0, 4], [2, 3]])
      end
    end
  end

  describe "#my_transpose" do
    context "when given a matrix" do
      it "transposes the matrix" do
        rows = [
            [0, 1, 2],
            [3, 4, 5],
            [6, 7, 8]
          ]
        expect(rows.my_transpose).to eq(rows.transpose)
      end
    end
  end

  describe "#stock picker" do
    context "when given an set of stock prices" do
      it "returns the most profitable pair of days" do
        expect([150,175,1,10,10,100,10].stock_picker).to eq([2,5])
      end
    end
  end
end
