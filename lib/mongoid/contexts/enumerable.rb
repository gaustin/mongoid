# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Enumerable
      include Ids, Paging
      attr_reader :criteria

      delegate :blank?, :empty?, :first, :last, :to => :execute
      delegate :documents, :options, :selector, :to => :criteria

      # Return aggregation counts of the grouped documents. This will count by
      # the first field provided in the fields array.
      #
      # Returns:
      #
      # A +Hash+ with field values as keys, count as values
      def aggregate
        counts = {}
        group.each_pair { |key, value| counts[key] = value.size }
        counts
      end

      # Get the average value for the supplied field.
      #
      # Example:
      #
      # <tt>context.avg(:age)</tt>
      #
      # Returns:
      #
      # A numeric value that is the average.
      def avg(field)
        total = sum(field)
        total ? (total.to_f / count) : nil
      end

      # Gets the number of documents in the array. Delegates to size.
      def count
        @count ||= documents.size
      end

      # Gets an array of distinct values for the supplied field across the
      # entire array or the susbset given the criteria.
      #
      # Example:
      #
      # <tt>context.distinct(:title)</tt>
      def distinct(field)
        execute.collect { |doc| doc.send(field) }.uniq
      end

      # Enumerable implementation of execute. Returns matching documents for
      # the selector, and adds options if supplied.
      #
      # Returns:
      #
      # An +Array+ of documents that matched the selector.
      def execute(paginating = false)
        limit(documents.select { |document| document.matches?(selector) })
      end

      # Groups the documents by the first field supplied in the field options.
      #
      # Returns:
      #
      # A +Hash+ with field values as keys, arrays of documents as values.
      def group
        field = options[:fields].first
        documents.group_by { |doc| doc.send(field) }
      end

      # Create the new enumerable context. This will need the selector and
      # options from a +Criteria+ and a documents array that is the underlying
      # array of embedded documents from a has many association.
      #
      # Example:
      #
      # <tt>Mongoid::Contexts::Enumerable.new(criteria)</tt>
      def initialize(criteria)
        @criteria = criteria
      end

      # Iterate over each +Document+ in the results. This can take an optional
      # block to pass to each argument in the results.
      #
      # Example:
      #
      # <tt>context.iterate { |doc| p doc }</tt>
      def iterate(&block)
        execute.each(&block)
      end

      # Get the largest value for the field in all the documents.
      #
      # Returns:
      #
      # The numerical largest value.
      def max(field)
        determine(field, :>=)
      end

      # Get the smallest value for the field in all the documents.
      #
      # Returns:
      #
      # The numerical smallest value.
      def min(field)
        determine(field, :<=)
      end

      # Get one document.
      #
      # Returns:
      #
      # The first document in the +Array+
      alias :one :first

      # Get the sum of the field values for all the documents.
      #
      # Returns:
      #
      # The numerical sum of all the document field values.
      def sum(field)
        sum = documents.inject(nil) do |memo, doc|
          value = doc.send(field)
          memo ? memo += value : value
        end
      end

      protected
      # If the field exists, perform the comparison and set if true.
      def determine(field, operator)
        matching = documents.inject(nil) do |memo, doc|
          value = doc.send(field)
          (memo && memo.send(operator, value)) ? memo : value
        end
      end

      # Limits the result set if skip and limit options.
      def limit(documents)
        skip, limit = options[:skip], options[:limit]
        if skip && limit
          return documents.slice(skip, limit)
        elsif limit
          return documents.first(limit)
        end
        documents
      end
    end
  end
end
