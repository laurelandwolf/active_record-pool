module ActiveRecord
  class Base
    def self.pool(columns:, query: self, table: self.arel_table, size: ActiveRecord::Pool::DEFAULT_SIZE, serializer: ActiveRecord::Pool::DEFAULT_SERIALIZER, &iteration)
      ActiveRecord::Pool.new(columns: columns, query: query, table: table, size: size, serializer: serializer, model: self, &iteration)
    end
  end
end
