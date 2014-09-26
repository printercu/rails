require 'active_support/lazy_load_hooks'
require 'active_record/explain_registry'

module ActiveRecord
  module Explain
    # Runs EXPLAIN on the query or queries triggered by this relation and
    # returns the result as a string. The string is formatted imitating the
    # ones printed by the database shell.
    #
    # Note that this method actually runs the queries, since the results of some
    # are needed by the next ones when eager loading is going on.
    #
    # Please see further details in the
    # {Active Record Query Interface guide}[http://guides.rubyonrails.org/active_record_querying.html#running-explain].
    def explain(*args)
      #TODO: Fix for binds.
      exec_explain(collecting_queries_for_explain { exec_queries }, *args)
    end

    # Executes the block with the collect flag enabled. Queries are collected
    # asynchronously by the subscriber and returned.
    def collecting_queries_for_explain # :nodoc:
      ExplainRegistry.collect = true
      yield
      ExplainRegistry.queries
    ensure
      ExplainRegistry.reset
    end

    # Makes the adapter execute EXPLAIN for the tuples of queries and bindings.
    # Returns a formatted string ready to be logged.
    def exec_explain(queries, *args) # :nodoc:
      options = args.last
      options = {} unless options.is_a?(Hash)
      explains = queries.map do |sql, bind|
        {
          sql:      sql,
          bind:     bind.map { |col, val| [col.name, val] },
          explain:  connection.explain(sql, bind, *args),
        }
      end

      if options[:raw]
        explains
      else
        str = explains.map { |result|
          bind = result[:bind]
          bind_msg = " #{bind.inspect}" if bind.any?
          "EXPLAIN for: #{result[:sql]}#{bind_msg}\n#{result[:explain]}"
        }.join("\n")

        # Overriding inspect to be more human readable, especially in the console.
        def str.inspect
          self
        end

        str
      end
    end
  end
end
