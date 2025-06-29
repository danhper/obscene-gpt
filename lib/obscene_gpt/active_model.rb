if defined?(ActiveModel)
  class ObsceneContentValidator < ActiveModel::EachValidator
    def validate(record)
      to_validate = compute_attributes_to_validate(record)
      return if to_validate.empty?

      results = ObsceneGpt.detect_many(to_validate.values)
      format_errors(record, to_validate, results)
    end

    private

    def compute_attributes_to_validate(record)
      attributes.map do |attribute|
        value = record.read_attribute_for_validation(attribute)
        next if value.nil? || value.blank?

        [attribute, prepare_value_for_validation(value, record, attribute)]
      end.compact.to_h
    end

    def format_errors(record, to_validate, results)
      results.each_with_index do |result, index|
        attribute = to_validate.keys[index]
        threshold = option_for(:threshold, attribute, ObsceneGpt.configuration.profanity_threshold)

        if result[:obscene] && result[:confidence] >= threshold
          message = result[:reasoning] || "contains inappropriate content"
          record.errors.add(attribute, :obscene_content, message: message)
        end
      end
    end

    def option_for(key, attribute, default = nil)
      (options[attribute] && options[attribute][key]) ||
        options[key] || default
    end
  end
end
