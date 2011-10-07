require 'rubygems'
require 'net/http'
require 'json'
require 'cgi'

module Factual
  # The start point of using Factual API
  class Api

    def initialize(opts)
      @api_key = opts[:api_key]
      @version = 3
      @domain  = opts[:domain] || "api.v#{@version}.factual.com"
      @debug   = opts[:debug]

      @adapter = Adapter.new(@api_key, @version, @domain, @debug)
    end

    def get_table(table_key)
      Table.new(table_key, @adapter)
    end

    # Get the token of a {shadow account}[http://wiki.developer.factual.com/f/shadow_input.png], it is a partner-only feature.
    # def get_token(unique_id)
    #   return @adapter.get_token(unique_id)
    # end
  end


  class Table
    attr_accessor :name, :key, :description, :included_rows, :created_at, :updated_at, :fields, :geo_enabled, :downloadable
    attr_accessor :id, :title, :last_update_date
    
    attr_accessor :page_size, :page
    attr_reader   :adapter # :nodoc:

    def initialize(table_name, adapter) # :nodoc:
      @table_name = table_name
      @adapter   = adapter
      @schema    = adapter.schema(@table_name)
      @page_size = Adapter::DEFAULT_LIMIT
      @page      = 1
      
      [:id, :title, :description, :geo_enabled, :last_update_date, :fields, :included_rows].each do |attr|
        k = camelize(attr)
        self.send("#{attr}=", @schema[k]) 
      end
     
      @fields_lookup = {}               
      @fields.each do |f|
        @fields_lookup[f['name']] = f
      end
    end

    def page(page_num, page_size_hash=nil)
      @page_size = page_size_hash[:size] || @page_size if page_size_hash
      @page = page_num.to_i if page_num.to_i > 0

      return self
    end

    def search(*queries)
      @searches = queries
      return self
    end

    def filter(filters)
      @filters = filters
      return self
    end

    def sort(*sorts)
      @sorts = sorts
      return self
    end

    def find_one
      resp = @adapter.read_table(@table_name, 
          :filters   => @filters, 
          :searches  => @searches, 
          :sorts     => @sorts, 
          :page_size => 1)

      row_data = resp["data"].first

      if row_data
        factual_id = row_data["factual_id"]
        return Row.new(self, factual_id, row_data)
      else
        return nil
      end
    end

    def each_row
      resp = @adapter.read_table(@table_name, 
          :filters   => @filters, 
          :searches  => @searches, 
          :sorts     => @sorts, 
          :page_size => @page_size, 
          :page      => @page)

      @total_rows = resp["included_rows"]
      rows = resp["data"]
      
      rows.each do |row_data|
        factual_id = row_data["factual_id"]
        row = Row.new(self, factual_id, row_data) 
        yield(row) if block_given?
      end
    end

    ## Not supported by v3 beta yet
    
    # def input(values_hash, opts={})
    #   values = values_hash.collect do |field_ref, value|
    #     field = @fields_lookup[field_ref.to_s]
    #     raise Factual1::ArgumentError.new("Wrong field ref.") unless field
    #     
    #     { :fieldId => field['id'], :value => value}
    #   end
    # 
    #   hash = opts.merge({ :values => values })
    # 
    #   ret = @adapter.input(@table_key, hash)
    #   return ret
    # end
    # 
    # def input_with_token(token, values_hash, opts={})
    #   return input(values_hash, opts.merge({ :token => token }))
    # end

    private

    def camelize(str)
      s = str.to_s.split("_").collect{ |w| w.capitalize }.join
      s[0].chr.downcase + s[1..-1]
    end
  end

  class Row
    attr_reader :factual_id, :subject

    def initialize(table, factual_id, row_data=[]) # :nodoc:
      @factual_id = factual_id
      @table        = table
      @fields       = @table.fields
      @table_name   = @table.name
      @adapter      = @table.adapter
      
      @facts_hash  = {}      
      @fields.each_with_index do |f, idx|        
        @facts_hash[f["name"]] = Fact.new(@table, @factual_id, f, row_data[f["name"]])
      end
    end

    def [](field_ref)
      @facts_hash[field_ref]
    end
  end

  class Fact
    attr_reader :value, :subject_key, :field_ref, :field 

    def initialize(table, subject_key, field, value) # :nodoc:
      @value = value 
      @field = field
      @subject_key = subject_key

      @table_key = table.key
      @adapter   = table.adapter
    end

    def field_ref # :nodoc:
      @field["field_ref"]
    end

    def input(value, opts={})
      return false if value.nil?

      hash = opts.merge({
        :subjectKey => @subject_key.first,
        :values     => [{
          :fieldId    => @field['id'],
          :value      => value }]
      })

      @adapter.input(@table_key, hash)
      return true
    end

    # Just return the value
    def to_s
      @value
    end

    # Just return the value
    def inspect
      @value
    end
  end


  class Response
    def initialize(obj)
      @obj = obj
    end

    def [](*keys)
      begin
        ret = @obj
        keys.each do |key|
          ret = ret[key]
        end

        if ret.is_a?(Hash)
          return Response.new(ret)
        else
          return ret
        end
      rescue Exception => e
        Factual1::ResponseError.new("Unexpected API response")
      end
    end
  end

  class Adapter # :nodoc:
    CONNECT_TIMEOUT = 30
    DEFAULT_LIMIT   = 20

    def initialize(api_key, version, domain, debug=false)
      @domain = domain
      @base   = "" # add key somewhere
      @debug  = debug
      @key = "?KEY=#{api_key}"
    end

    def api_call(url)
      k = url.include?('?') ? ("&"+@key.delete('?')) : @key
      api_url = @base + url + k
      puts "[Factual API Call] http://#{@domain}#{api_url}" if @debug

      json = "{}"
      begin
        Net::HTTP.start(@domain, 80) do |http|
          response = http.get(api_url)
          json     = response.body
        end
      rescue Exception => e
        raise ApiError.new(e.to_s + " when getting " + api_url)
      end
      
      obj  = JSON.parse(json)
      resp = Factual::Response.new(obj)
      
      raise ApiError.new(resp["error"]) if resp["status"] == "error"
      return resp
    end

    def schema(table_name)
      url  = "/t/#{table_name}/schema.json"
      resp = api_call(url)
      return resp["response"]["view"]
    end

    ## Dont see any equivalent in v3 yet
    # def read_row(table_name, factual_id)
    #   url  = "/t/#{table_name}/read.jsaml?factual_id=#{factual_id}"
    #   resp = api_call(url)
    #   
    #   row_data = resp["response", "data", 0] || []
    #   row_data.unshift # remove the subject_key
    #   return row_data
    # end

    def read_table(table_name, options={})
      filters   = options[:filters]
      sorts     = options[:sorts]
      searches  = options[:searches]
      page_size = options[:page_size]
      page      = options[:page]

      limit = page_size.to_i 
      limit = DEFAULT_LIMIT unless limit > 0
      offset = (page.to_i - 1) * limit
      offset = 0 unless offset > 0

      total_query = ""
      total_query += "&filters=" + CGI.escape(filters.to_json) if filters
      total_query += "&q=" + CGI.escape(searches.to_json) if searches
          
      if sorts
        sorts = sorts[0] if sorts.length == 1
        sort_str = ""
        sorts.each { |key, value| sort_str += "#{key}:#{value}" }
        sorts_query = "&sort=" + sort_str
      end    

      url  = "/t/#{table_name}.json?limit=#{limit}&offset=#{offset}" 
      url += total_query.to_s + sorts_query.to_s
      resp = api_call(url)

      return resp["response"]
    end

    ## Not supported by v3 beta yet
    
    # def get_token(unique_id)
    #   url  = "/sessions/get_token?uniqueId=#{unique_id}"
    #   resp = api_call(url)
    # 
    #   return resp["string"]
    # end
    # 
    # def input(table_name, params)
    #   token = params.delete(:token)
    #   query_string = params.to_a.collect do |k,v| 
    #     v_string = (v.is_a?(Hash) || v.is_a?(Array)) ? v.to_json : v.to_s
    #     CGI.escape(k.to_s) + '=' + CGI.escape(v_string) 
    #   end.join('&')
    # 
    #   url  = "/t/#{table_name}/input.js?" + query_string
    #   url += "&token=" + token if token
    #   resp = api_call(url)
    # 
    #   return resp['response']
    # end
  end

  # Exception classes for Factual Errors  
  class ApiError < StandardError; end
  class ArgumentError < StandardError; end
  class ResponseError < StandardError; end
end
