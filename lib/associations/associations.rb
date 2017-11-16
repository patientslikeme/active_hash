module ActiveHash
  module Associations
    module ActiveRecordExtensions
      def belongs_to_active_hash(association_id, options = {})
        options = {
          :class_name => association_id.to_s.camelize,
          :foreign_key => association_id.to_s.foreign_key,
        }.merge(options)
        # Define default primary_key with provided class_name if any
        options[:primary_key] ||= options[:class_name].constantize.primary_key

        define_method(association_id) do
          options[:class_name].constantize.find_by(options[:primary_key] => send(options[:foreign_key]))
        end

        define_method("#{association_id}=") do |new_value|
          send "#{options[:foreign_key]}=", new_value ? new_value.send(options[:primary_key]) : nil
        end
      end
    end
  end
end
