require './lib/factual'
require './test/unit/helper'

class TableTest < Factual::TestCase # :nodoc:
  def setup
    api = Factual::Api.new(:api_key => API_KEY, :debug => DEBUG_MODE)
    @table = api.get_table(TABLE_NAME)
  end

  def test_metadata 
    assert_equal @table.title, "Places"
  end

  def test_each_row
    states = []
    @table.each_row do |state_info|
      fact = state_info['region']
      states << fact.value
    end
    
    assert_equal states.length, TOTAL_ROWS
  end

  def test_search
    row = @table.search('hawaii').find_one
    assert_equal row["region"].value, "HI"

    row = @table.search('hi', 'hawaii').find_one
    assert_equal row["region"].value, "HI"
  end

  def test_filtering
    row = @table.filter(:name => 'Starbucks').find_one
    assert_equal row["region"].value, "DC"

    row = @table.filter(:name => { '$bw' => 'Starbucks' }).find_one
    assert_equal row["region"].value, "TN"
  end

  def test_sorting
    row = @table.sort(:name => 'asc').find_one
    assert_equal row["region"].value, "TX"
  end

  def test_paging
    regions = []
    @table.page(2, :size => 2).each_row do |row|
      regions << row['region'].value
    end

    assert_equal regions.length, 2
    assert_not_equal regions[0], "TX"
  end

  # def test_adding_row
  #   row = @table.input(:two_letter_abbrev => 'NE', :state => 'Nebraska')
  # end
  
  # def test_row
  #   row = Factual::Row.new(@table, FACTUAL_ID)
  #   # assert_equal row['region'].value, 'CA'
  # end
end
