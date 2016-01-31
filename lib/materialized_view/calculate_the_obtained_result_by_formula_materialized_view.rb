module CalculateTheObtainedResultByFormulaMaterializedView

  def self.create_view_sql table_name='calculate_the_obtained_result_by_formulas'

    colums = ConditionItem::OBTAINED_RESULT.map do |condition_type, obtained_results|
                obtained_results.values.map do |obtained_result|
                  ConditionItem::FORMULA_FOR_OBTAINED_RESULT[obtained_result].split(/\W/).reject(&:blank?)
                end
              end.flatten.uniq
    colums_list = colums.join(', ')
    formula = colums.map { |c| "SUM(#{c}) OVER w AS #{c}" }.join(', ')

    unless ActiveRecord::Base.connection.table_exists? table_name
      <<-SQL
        CREATE MATERIALIZED VIEW #{table_name} AS
          SELECT
            #{formula},
            modified_daily_players_statistics.serial_id,
            modified_daily_players_statistics.username,
            modified_daily_players_statistics.cid,
            modified_daily_players_statistics.an_id,
            modified_daily_players_statistics.transaction_date
          FROM modified_daily_players_statistics
          LEFT JOIN modified_daily_statistics_players ON
            modified_daily_players_statistics.cid = modified_daily_statistics_players.cid
          GROUP BY
            #{colums_list},
            modified_daily_players_statistics.transaction_date,
            modified_daily_players_statistics.serial_id,
            modified_daily_players_statistics.username,
            modified_daily_players_statistics.cid,
            modified_daily_players_statistics.an_id
          WINDOW w AS (
            PARTITION BY
              modified_daily_players_statistics.serial_id,
              modified_daily_players_statistics.username,
              modified_daily_players_statistics.cid,
              modified_daily_players_statistics.an_id
            ORDER BY modified_daily_players_statistics.transaction_date
            ROWS UNBOUNDED PRECEDING
          )
          ORDER BY
            modified_daily_players_statistics.username,
            modified_daily_players_statistics.transaction_date
      SQL
    end || ''
  end
end
