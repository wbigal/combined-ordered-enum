# The aim of this class is to take a number of ordered enumerators and then
# create an Enumerator that emits their values in ascending order.
#
# Some assumptions:
#   * The enumerators passed in emit their values in ascending order.
#   * The enumerators emit values which are Comparable[1] with each other.
#   * The enumerators can be finite *or* infinite.
#
# Please note: Your code must not only pass the tests, but also be a well
# behaved Enumerator.
#
# The Enumerator[2] documentation might be useful.
#
# [1] http://www.ruby-doc.org/core-1.9.3/Comparable.html
# [2] http://www.ruby-doc.org/core-1.9.3/Enumerator.html
#
# This is a stub implementation that causes failures in in the test suite, but
# no errors.
#
# You can run the test suite with: `ruby combined_ordered_enumerator.rb`.
class CombinedOrderedEnumerator < Enumerator
  class UnorderedEnumerator < RuntimeError
    attr_reader :enumerator

    def initialize(enumerator)
      @enumerator = enumerator
    end
  end

  attr_reader :enumerators

  def initialize(*enumerators)
    @enumerators = enumerators
    super() do |yielder|
    end
  end

  def take(n)
    items = []
    @enumerators.each do |enum|
      raise UnorderedEnumerator.new(enum) unless ordered?(enum, n)
      items.concat enum.lazy.take(n).to_a
    end
    items.sort.first(n)
  end

  def first(n)
    items = []
    @enumerators.each do |enum|
      items.concat enum.lazy.first(n).to_a
    end
    items.sort.first(n)
  end

  def map(&block)
    items = []
    @enumerators.each do |enum|
      items.concat enum.to_a
    end
    block.call(items.sort)
  end

  private
    def ordered?(enum, n)
      enum.take(n).each_cons(2).all? { |pair| pair.first <= pair.last }
    end
end

if $0 == __FILE__
  require 'minitest/autorun'
  require 'minitest/pride'

  class CombinedOrderedEnumeratorTest < Minitest::Test
    def test_enumerating_nothing
      enumerator = CombinedOrderedEnumerator.new()
      assert_equal [], enumerator.first(10)
    end

    def test_enumerating_with_a_single_enumerator
      enumerator = CombinedOrderedEnumerator.new((1..5).to_enum)
      assert_equal [1, 2, 3, 4, 5], enumerator.take(10)
    end

    def test_enumerating_with_two_empty_arrays
      enumerator = CombinedOrderedEnumerator.new([].to_enum, [].to_enum)
      assert_equal [], enumerator.to_a
    end

    def test_enumerating_with_one_empty_array_and_finite_sequence
      enumerator = CombinedOrderedEnumerator.new([].to_enum, (1..10).to_enum)
      assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], enumerator.map { |x| x }
    end

    def test_enumerating_with_one_empty_array_and_finite_sequence_with_switched_args
      enumerator = CombinedOrderedEnumerator.new((1..10).to_enum, [].to_enum)
      assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], enumerator.first(20)
    end

    def test_enumerating_an_infinite_sequence_and_finite_one
      enumerator = CombinedOrderedEnumerator.new(fibonacci, (1..10).to_enum)
      assert_equal [0, 1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 13, 21, 34], enumerator.take(20)
    end

    def test_enumerating_two_infinite_sequences
      enumerator = CombinedOrderedEnumerator.new(fibonacci, sum_of_natural_numbers)
      assert_equal [0, 1, 1, 1, 2, 3, 3, 5, 6, 8, 10, 13, 15, 21, 21, 28, 34, 36, 45, 55], enumerator.first(20)
    end

    def test_enumerating_three_finite_sequences
      enumerator = CombinedOrderedEnumerator.new((1..5).to_enum, (1..3).to_enum, (4..10).to_enum)
      assert_equal [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 8, 9, 10], enumerator.take(20)
    end

    def test_enumerating_three_infinite_sequences
      enumerator = CombinedOrderedEnumerator.new(fibonacci, fibonacci, fibonacci)
      assert_equal [0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2], enumerator.first(12)
    end

    def test_raises_unordered_enumerator_exception_if_enumerator_isnt_in_ascending_order
      enumerator = CombinedOrderedEnumerator.new(10.downto(1))

      assert_raises(CombinedOrderedEnumerator::UnorderedEnumerator) do
        enumerator.take(20)
      end
    end

    def test_raising_unordered_enumerator_should_reference_enumerator
      decending_enumerator = 10.downto(1)
      enumerator = CombinedOrderedEnumerator.new(decending_enumerator)

      begin
        enumerator.take(2)
        assert false
      rescue CombinedOrderedEnumerator::UnorderedEnumerator => exception
        assert_equal decending_enumerator, exception.enumerator
      end
    end

    private

    class FibonacciEnumerator < Enumerator
      def initialize
        super() do |yielder|
          a, b = 0, 1

          loop do
            yielder.yield a
            a, b = b, (a + b)
          end
        end
      end
    end

    def fibonacci
      FibonacciEnumerator.new
    end

    class SumOfNaturalNumbersEnumerator < Enumerator
      def initialize
        super() do |yielder|
          n = 1

          loop do
            yielder.yield((n * (n + 1)) / 2)
            n += 1
          end
        end
      end
    end

    def sum_of_natural_numbers
      SumOfNaturalNumbersEnumerator.new
    end
  end
end
