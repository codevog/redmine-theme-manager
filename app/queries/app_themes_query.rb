class AppThemesQuery < Query

  self.queried_class = AppTheme

  self.available_columns = [
      QueryColumn.new(:uid, :sortable => "#{AppTheme.table_name}.uid", :caption => I18n.t('field_uid')),
      QueryColumn.new(:name, :sortable => "#{AppTheme.table_name}.name", :caption => I18n.t('field_name')),
  ]

  def default_columns_names
    @default_columns_names ||= [:uid, :name]
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {}
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end

  def initialize_available_filters
    add_available_filter "uid", :type => :string, :label => 'uid'
  end

  def objects_scope(options={})
    self.queried_class.where(statement).
        where(options[:conditions])
  end

  def object_count
    objects_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    objects_scope(options).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end


end