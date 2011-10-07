require './test/unit/helper'
require './lib/factual'

class AdapterTest < Factual::TestCase # :nodoc:
  def setup
    @adapter = Factual::Adapter.new(API_KEY, API_VERSION, API_DOMAIN, DEBUG_MODE)
  end

  def test_read_row
    # row_data = @adapter.read_row(TABLE_NAME, FACTUAL_ID)
    # assert_not_nil row_data
  end

  def test_correct_request
    url = "/t/#{TABLE_NAME}/schema.json"

    assert_nothing_raised do
      resp = @adapter.api_call(url)
    end
  end

  def test_wrong_request
    url = "/t/#{WRONG_KEY}/schema.json"
    assert_raise JSON::ParserError do
      resp = @adapter.api_call(url)
    end
  end

  def test_getting_schema
    schema = @adapter.schema(TABLE_NAME)

    assert_not_nil schema
    assert_equal schema['title'], TABLE_NAME.capitalize
  end

  def test_reading_table_with_filter
    resp = @adapter.read_table(TABLE_NAME, :filters => {:name => 'Starbucks'})
    assert_equal resp['included_rows'], 20
  end

end
