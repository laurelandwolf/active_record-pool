module ActiveRecord
  require_relative "base_extension"

  class Pool
    require_relative "pool/version"

    DEFAULT_SIZE = 24
    DEFAULT_SERIALIZER = ::JSON
    EMPTY_HASH = {}

    # `query` is either an ActiveRecord query object or arel
    # `columns` is a list of columns you want to have during the transaction
    # `table` is the Arel::Table that operations are cast against
    # `size` is the maximum number of running iterations in the pool, default: 24
    # `serializer` is the #dump duck for Array & Hash values, default: JSON
    # `model` is an ActiveRecord model
    # `transaction` is the process you want to run against your database
    def initialize(query:, columns:, table:, size:, serializer:, model:, &transaction)
      @query = query
      @serializer = serializer
      @table = table
      qutex = Mutex.new

      queue = case
      when activerecord?
        @query.pluck(*@columns)
      when arel?
        ActiveRecord::Base.connection.execute(@query.to_sql).map(&:values)
      when tuple?
        @query.map { |result| result.slice(*columns).values }
      when twodimensional?
        @query
      else
        raise ArgumentError, 'query wasn\'t recognizable, please use some that looks like a: ActiveRecord::Base, Arel::SelectManager, Array[Hash], Array[Array]'
      end

      puts "Migrating #{queue.count} #{table} records"

      # Spin up a number of threads based on the `maximum` given
      1.upto(size).map do
        Thread.new do
          loop do
            # Try to get a new queue item
            item = qutex.synchronize { queue.shift }

            if item.nil?
              # There is no more work
              break
            else
              # Wait for a free connection
              model.connection_pool.with_connection do
                model.transaction do
                  # Execute each statement coming back
                  Array[instance_exec(*item, &transaction)].each do |instruction|
                    next if instruction.nil?
                    model.connection.execute(instruction.to_sql)
                  end
                end
              end
            end
          end
        end
      end.map(&:join)
    end

    private def activerecord?
      @query.kind_of?(ActiveRecord::Base) || @query.kind_of?(ActiveRecord::Relation) || @query.try(:<, ActiveRecord::Base)
    end

    private def arel?
      @query.kind_of?(Arel::SelectManager)
    end

    private def tuple?
      @query.kind_of?(Array) && @query.first.kind_of?(Hash)
    end

    private def twodimensional?
      @query.kind_of?(Array) && @query.first.kind_of?(Array)
    end

    private def update(id, data)
      Arel::UpdateManager.new.table(@table).where(@table[:id].eq(id)).set(serialize(data))
    end

    private def insert(data)
      Arel::InsertManager.new.tap { |m| m.insert(serialize(data)) }
    end

    private def delete(id)
      Arel::DeleteManager.new.from(@table).where(@table[:id].eq(id))
    end

    private def serialize(data)
      data.inject(EMPTY_HASH) do |state, (key, value)|
        if value.is_a?(Array) || value.is_a?(Hash)
          state.merge(@table[key] => @serializer.dump(value))
        else
          state.merge(@table[key] => value)
        end
      end
    end
  end
end
