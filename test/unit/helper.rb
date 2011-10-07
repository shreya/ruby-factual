require 'test/unit'

module Factual
  class TestCase < Test::Unit::TestCase # :nodoc:
    # api_key for demo, read-only 
    API_KEY     = 'p7kwKMFUSyVi64FxnqWmeSDEI41kzE3vNWmwY9Zi'
    API_VERSION = 3
    API_DOMAIN  = "api.v#{API_VERSION}.factual.com"
    DEBUG_MODE  = false

    TABLE_NAME   = 'places'
    WRONG_KEY   = '$1234$'
    TOTAL_ROWS  = 20

    STATE_FIELD_ID = 14
    FACTUAL_ID    = "f11426ea-abd8-46c7-be17-a2b950d04535"

    def test_default
    end
  end
end
