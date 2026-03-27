require "csv"

module Exports
  class CsvBuilder
    def self.call(headers:, collection:, batch_size: 1000, &row_builder)
      raise ArgumentError, "row_builder block is required" unless block_given?

      CSV.generate(headers: true) do |csv|
        csv << headers
        each_record(collection, batch_size: batch_size) do |record|
          csv << row_builder.call(record)
        end
      end
    end

    def self.each_record(collection, batch_size:)
      if collection.respond_to?(:find_each)
        collection.find_each(batch_size: batch_size) { |record| yield record }
      else
        Array(collection).each { |record| yield record }
      end
    end

    private_class_method :each_record
  end
end
