## Sample Usage

A block of code is worth a thousand words.
Supports Factual API v3 beta

    require 'rubygems'
    gem 'ruby-factual'
    require 'factual'
    
    api = Factual::Api.new(:api_key => "<YOUR_FACTUAL_API_KEY>")
    
    # get table and its metadata
    # table metadata: name, description, title, geo_enabled etc
    table = api.get_table("places")
    puts table.name, table.title
    
    # read rows after filtering and sorting
    table.filter(:name => "CA").sort(:name => 'asc').page(1, :size => 5).each_row do |state_info|

      fact = state_info["region"]
      puts fact.value, fact.subject_keys
    end
    
    # you can also get rows by search
    row = table.search("hawaii").find_one
    puts row["region"]
