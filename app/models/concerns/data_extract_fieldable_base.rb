module DataExtractFieldableBase
  extend ActiveSupport::Concern

  def exportable_columns
    cols = self.class.exportable_columns.dup
    cols.concat form_fields_columms if form_fields.any?
    cols
  end

  def columns_definitions
    @columns_definitions ||= (super.dup.tap do |definitions|
      form_fields.each do |ff|
        definitions.merge!(
          if ff.is_hashed_value?
            Hash[ff.options.map { |o| ["ff_#{ff.id}_#{o.id}".to_sym, "join_ff_#{ff.id}.value->'#{o.id}'"] }]
          else
            { "ff_#{ff.id}".to_sym => "join_ff_#{ff.id}.value->'value'" }
          end
        )
      end if form_fields.any?
    end)
  end

  def form_fields_columms
    @form_fields_columms ||= [].tap do |cols|
      form_fields.map do |ff|
        if ff.is_hashed_value?
          cols.concat ff.options.map { |o| ["ff_#{ff.id}_#{o.id}", "#{ff.name}: #{o.name}"] }
        else
          cols << ["ff_#{ff.id}", ff.name]
        end
      end.flatten
    end
  end

  def add_joins_to_scope(s)
    add_form_field_joins super
  end

  def add_form_field_joins(s)
    return s unless form_fields.any?
    selected_form_field_ids.each do |id|
      s = s.joins("LEFT JOIN #{self.class::RESULTS_VIEW_NAME} join_ff_#{id} "\
                  "ON join_ff_#{id}.form_field_id=#{id} AND "\
                  "   join_ff_#{id}.#{model.name.underscore}_id=#{model.table_name}.id")
    end
    s
  end

  def selected_form_field_ids
    columns
      .select { |c| c =~ /\Aff_([0-9]+)(_[0-9]+)?\z/ }
      .map { |c| c.gsub(/ff_([0-9]+)(_[0-9]+)?/, '\1') }
      .uniq
  end
end