module ActiveHash

  class RecordNotFound < StandardError
  end

  class ReservedFieldError < StandardError
  end

  class IdError < StandardError
  end

  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    class_attribute :_data, :default_attributes #, :dirty

    class << self
      def primary_key
        "id"
      end

      def field_names
        @field_names ||= []
      end

      def data
        _data
      end

      def data=(array_of_hashes)
        @records = nil
        reset_record_index
        self._data = array_of_hashes
        if array_of_hashes
          auto_assign_fields(array_of_hashes)
          array_of_hashes.each do |hash|
            insert new(hash)
          end
        end
      end

      def exists?(record)
        if record.id.present?
          record_index[record.id.to_s].present?
        end
      end

      def insert(record)
        @records ||= []
        record.id ||= next_id
        validate_unique_id(record)

        add_to_record_index({ record.id.to_s => @records.length })
        @records << record
      end

      def next_id
        max_record = all.max { |a, b| a.id <=> b.id }
        if max_record.nil?
          1
        elsif max_record.id.is_a?(Numeric)
          max_record.id.succ
        end
      end

      private def record_index
        @record_index ||= {}
      end

      private def reset_record_index
        record_index.clear
      end

      private def add_to_record_index(entry)
        record_index.merge!(entry)
      end

      private def validate_unique_id(record)
        raise IdError.new("Duplicate ID found for record #{record.attributes.inspect}") if record_index.has_key?(record.id.to_s)
      end

      def all
        @records ||= []
      end

      def where(options)
        return @records if options.blank?

        # use index if searching by id
        if options.key?(:id) || options.key?("id")
          ids = (options.delete(:id) || options.delete("id"))
          candidates = Array.wrap(ids).map { |id| find_by_id(id) }.compact
        end
        return candidates if options.blank?

        (candidates || @records || []).select do |record|
          match_options?(record, options)
        end
      end

      def find_by(options)
        where(options).first
      end

      def find_by!(options)
        find_by(options) || (raise RecordNotFound.new("Couldn't find #{name}"))
      end

      private def match_options?(record, options)
        options.all? do |col, match|
          if match.kind_of?(Array)
            match.include?(record[col])
          else
            record[col] == match
          end
        end
      end

      def find(id)
        case id
          when nil
            nil
          when Array
            id.map { |i| find(i) }
          else
            find_by_id(id) || begin
              raise RecordNotFound.new("Couldn't find #{name} with ID=#{id}")
            end
        end
      end

      def find_by_id(id)
        index = record_index[id.to_s]
        index and @records[index]
      end

      delegate :first, :last, :each, to: :all

      def fields(*args)
        options = args.extract_options!
        args.each do |field|
          field(field, options)
        end
      end

      def field(field_name, options = {})
        validate_field(field_name)
        field_names << field_name

        add_default_value(field_name, options[:default]) if options[:default]
        define_getter_method(field_name, options[:default])
        define_setter_method(field_name)
        define_interrogator_method(field_name)
      end

      private def validate_field(field_name)
        if [:attributes].include?(field_name.to_sym)
          raise ReservedFieldError.new("#{field_name} is a reserved field in ActiveHash.  Please use another name.")
        end
      end

      def add_default_value field_name, default_value
        self.default_attributes ||= {}
        self.default_attributes[field_name] = default_value
      end

      private def define_getter_method(field, default_value)
        unless instance_methods.include?(field.to_sym)
          define_method(field) do
            attributes[field].nil? ? default_value : attributes[field]
          end
        end
      end

      private def define_setter_method(field)
        method_name = :"#{field}="
        unless instance_methods.include?(method_name)
          define_method(method_name) do |new_val|
            @attributes[field] = new_val
          end
        end
      end

      private def define_interrogator_method(field)
        method_name = :"#{field}?"
        unless instance_methods.include?(method_name)
          define_method(method_name) do
            send(field).present?
          end
        end
      end

      private def auto_assign_fields(array_of_hashes)
        (array_of_hashes || []).inject([]) do |array, row|
          row.symbolize_keys!
          row.keys.each do |key|
            unless key.to_s == "id"
              array << key
            end
          end
          array
        end.uniq.each do |key|
          field key
        end
      end

      # Needed for ActiveRecord polymorphic associations
      def base_class
        ActiveHash::Base
      end
    end

    def initialize(attributes = {})
      attributes.symbolize_keys!
      @attributes = attributes
      attributes.dup.each do |key, value|
        send "#{key}=", value
      end
      yield self if block_given?
    end

    def attributes
      if self.class.default_attributes
        (self.class.default_attributes.merge @attributes).freeze
      else
        @attributes
      end
    end

    def [](key)
      attributes[key]
    end

    def id
      attributes[:id] ? attributes[:id] : nil
    end

    def id=(id)
      @attributes[:id] = id
    end

    def eql?(other)
      other.instance_of?(self.class) and not id.nil? and (id == other.id)
    end

    alias == eql?

    def hash
      id.hash
    end
  end
end
