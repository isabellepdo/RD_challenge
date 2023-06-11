require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    last_score = 0
    customer_success_balancing = []
    active_customer_success_order_score.each do |cs|
      customer_success_balancing << { id_cs: cs[:id], number_costumers: number_of_costumers_for_this(cs, last_score) }
      last_score = cs[:score] + 1
    end

    max_number_customers(customer_success_balancing)
  end

  def active_customer_success_order_score
    @customer_success.reject { |record| @away_customer_success.include?(record[:id]) }.sort_by { |record| record[:score] }
  end

  def number_of_costumers_for_this(cs, last_score)
    @customers.count do |customer|
      customer[:score] >= last_score && customer[:score] <= cs[:score]
    end
  end

  def max_number_customers(customer_success_balancing)
    max_number_customers = nil
    second_max_number_customers = nil

    customer_success_balancing.each do |record|
      number_costumers = record[:number_costumers]

      if max_number_customers.nil? || number_costumers > max_number_customers[:number_costumers]
        second_max_number_customers = max_number_customers
        max_number_customers = record
      elsif second_max_number_customers.nil? || number_costumers >= second_max_number_customers[:number_costumers]
        second_max_number_customers = record
      end
    end

    if second_max_number_customers && max_number_customers[:number_costumers] == second_max_number_customers[:number_costumers]
      0
    else
      max_number_customers[:id_cs]
    end
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  

  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
