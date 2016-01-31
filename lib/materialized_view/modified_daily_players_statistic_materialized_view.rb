module ModifiedDailyPlayersStatisticMaterializedView

  def self.refresh_view_sql table_name='daily_players_statistics'
    ProcessingStatusMonth.not_processed.map do |psm|
      general_sql(table_name, psm.months.all_month)
    end.join('; ')
  end

  def self.create_view_sql table_name='daily_players_statistics'
    general_sql(table_name)
  end

  def self.general_sql table_name, period=nil

    table = 'result'
    ggr = ConditionItem::FORMULA_FOR_OBTAINED_RESULT['ggr'].split(' ').map do |c|
            if c =~ /\w/
              [table, c].join('.')
            end || c
          end.join(' ')
    cpa_ngr = ConditionItem::FORMULA_FOR_OBTAINED_RESULT['ngr'].split(' ').map do |c|
                if c =~ /\w/
                  [table, c].join('.')
                end || c
              end.join(' ')
    revenue_share_ngr = ConditionStepItem::FORMULA_FOR_OBTAINED_RESULT['ngr'].split(' ').map do |c|
                          if c =~ /\w/
                            [table, c].join('.')
                          end || c
                        end.join(' ')

    date_range, date_range_for_delete = if period && period.class == Range
                  [
                    "WHERE (r.transaction_date BETWEEN '%s' AND '%s')" % period.minmax,
                    "WHERE transaction_date BETWEEN '%s' AND '%s'" % period.minmax
                  ]
                end

    <<-SQL
      DELETE FROM modified_daily_players_statistics #{date_range_for_delete};
      INSERT INTO modified_daily_players_statistics (
                    affiliate_name, affiliate_username,
                    affiliate_payment_system, transaction_date, cid, username, serial_id,
                    tracker_description, an_id, transaction_fees, deposits, netdeposits,
                    bankroll, poker_bets, poker_rake, net_win, poker_tournament_fees,
                    bonuses, manually_granted_bonuses, sharecost_bonus, fullcost_bonus,
                    converted_bonus_points, jp_adjsutments, returned_transaction,
                    no_of_casino_bets, casino_revenue, casino_bets, is_ftd, is_money_transfer,
                    is_blocked, date_of_data, processed, first_deposit_count,
                    date_of_first_deposit, registration_count, cpa_qualified, cpa_profit,
                    revenue_share_profit, profit, created_at, updated_at, ggr, ngr
      ) SELECT
          result.affiliate_name,
          result.affiliate_username,
          result.affiliate_payment_system,
          result.transaction_date,
          result.cid,
          result.username,
          result.serial_id,
          result.tracker_description,
          result.an_id,
          result.transaction_fees,
          result.deposits,
          result.netdeposits,
          result.bankroll,
          result.poker_bets,
          result.poker_rake,
          result.net_win,
          result.poker_tournament_fees,
          result.bonuses,
          result.manually_granted_bonuses,
          result.sharecost_bonus,
          result.fullcost_bonus,
          result.converted_bonus_points,
          result.jp_adjsutments,
          result.returned_transaction,
          result.no_of_casino_bets,
          result.casino_revenue,
          result.casino_bets,
          result.is_ftd,
          result.is_money_transfer,
          result.is_blocked,
          result.date_of_data,
          result.processed,
          CASE
            WHEN  (
                    SELECT MIN(w.transaction_date)
                    FROM #{table_name} w
                    WHERE
                      w.deposits <> 0 AND
                      w.serial_id = result.serial_id AND
                      w.cid = result.cid AND
                      w.username = result.username AND
                      w.an_id = result.an_id
                  ) = result.transaction_date THEN
              1
            ELSE
              0
            END AS first_deposit_count,
          (
            SELECT MIN(w.transaction_date)
            FROM #{table_name} w
            WHERE
              w.deposits <> 0 AND
              w.serial_id = result.serial_id AND
              w.cid = result.cid AND
              w.username = result.username AND
              w.an_id = result.an_id
          ) AS date_of_first_deposit,
          result.registration_count,
          result.cpa_qualified,
          result.cpa_profit,
          result.revenue_share_profit,
          result.profit,
          result.created_at,
          result.updated_at,
          (
            #{ggr}
          ) AS ggr,
          CASE
            WHEN (result.type_of_transaction = 'cpa') THEN
              #{cpa_ngr}
            WHEN (result.type_of_transaction = 'revenue_share') THEN
              #{revenue_share_ngr} + (
                CASE
                  WHEN result.condition_option_id IS NOT NULL THEN
                    #{ConditionStepItem::NGR_SUBTRACT_CASINO_HOUSE_PROFIT}
                  ELSE
                    0
                  END
                )
            END AS ngr
        FROM (
          SELECT
            r.id,
            r.transaction_date,
            r.cid,
            r.username,
            COALESCE(history_of_players_changes.serial_id, r.serial_id) AS serial_id,
            COALESCE(history_of_players_changes.anid, r.an_id) AS an_id,
            COALESCE(
              r.deposits * COALESCE(
                (
                  SELECT tracker_commissions.value
                  FROM tracker_commissions
                  WHERE
                    tracker_commissions.tracker_id      = trackers.id AND
                    tracker_commissions.commission_type = 'for_deposits'
                  LIMIT 1
                ), 0) / 100 +
              (r.deposits - r.netdeposits) * COALESCE(
                (
                  SELECT tracker_commissions.value
                  FROM tracker_commissions
                  WHERE
                    tracker_commissions.tracker_id      = trackers.id AND
                    tracker_commissions.commission_type = 'for_withdrawals'
                  LIMIT 1), 0) / 100, 0) AS transaction_fees,
            r.deposits,
            r.netdeposits,
            r.bankroll,
            r.poker_bets,
            r.poker_rake,
            r.net_win,
            r.poker_tournament_fees,
            (r.fullcost_bonus + r.sharecost_bonus + COALESCE(bonuses.bonus_amount, 0)) AS bonuses,
            COALESCE(bonuses.bonus_amount, 0) AS manually_granted_bonuses,
            r.sharecost_bonus,
            r.fullcost_bonus,
            r.converted_bonus_points,
            r.jp_adjsutments,
            r.returned_transaction,
            r.no_of_casino_bets,
            r.casino_revenue,
            r.casino_bets,
            r.is_ftd,
            r.is_money_transfer,
            r.is_blocked,
            r.date_of_data,
            r.processed,
            CASE
              WHEN (modified_daily_statistics_players.registrationdate = r.transaction_date) THEN
                1
              ELSE
                0
              END AS registration_count,
            CASE
              WHEN (achievements.id IS NOT NULL) THEN
                1
              ELSE
                0
              END AS cpa_qualified,
            CASE
              WHEN modified_affiliate_payments.type_of_transaction = 'cpa' THEN
                COALESCE(modified_affiliate_payments.profit, 0)
              ELSE
                0
              END AS cpa_profit,
            CASE
              WHEN modified_affiliate_payments.type_of_transaction = 'revenue_share' THEN
                COALESCE(modified_affiliate_payments.profit, 0)
              ELSE
                0
              END AS revenue_share_profit,
            COALESCE(modified_affiliate_payments.profit, 0) AS profit,
            r.created_at,
            r.updated_at,
            conditions.type_of_transaction AS type_of_transaction,
            condition_options.id AS condition_option_id,
            affiliates.name AS affiliate_name,
            affiliates.username AS affiliate_username,
            CONCAT(
              affiliates.payment_system, ', ', affiliates.account_number
            ) AS affiliate_payment_system,
            trackers.description AS tracker_description
          FROM #{table_name} r
            LEFT JOIN daily_statistics_players ON
              daily_statistics_players.cid       = r.cid-- AND
              --daily_statistics_players.serial_id = r.serial_id AND
              --daily_statistics_players.anid      = r.an_id
            LEFT JOIN history_of_players_changes ON
              CASE
                WHEN (
                  SELECT COUNT(*)
                  FROM history_of_players_changes
                  WHERE (
                    history_of_players_changes.daily_statistics_player_id = daily_statistics_players.id AND
                    r.transaction_date >= history_of_players_changes.date
                  )
                ) >= 1 THEN
                  history_of_players_changes.id = (
                    SELECT history_of_players_changes.id
                    FROM history_of_players_changes
                    WHERE (
                      history_of_players_changes.daily_statistics_player_id = daily_statistics_players.id AND
                      r.transaction_date >= history_of_players_changes.date
                    )
                    ORDER BY history_of_players_changes.date DESC LIMIT 1
                  )
                ELSE
                  history_of_players_changes.id = 0
                END
            LEFT JOIN trackers ON
              trackers.tracker_code = COALESCE(history_of_players_changes.serial_id, r.serial_id)
            LEFT JOIN tracker_conditions ON
              tracker_conditions.tracker_id = trackers.id
            LEFT JOIN conditions ON
              conditions.id = tracker_conditions.condition_id
            LEFT JOIN condition_options ON
              condition_options.condition_id = conditions.id AND
              condition_options.name         = 'subtract_casino_house_profit' AND
              condition_options.aasm_state   = 'active'
            LEFT JOIN affiliates ON
              trackers.affiliate_id = affiliates.id
            LEFT JOIN modified_affiliate_payments ON
              modified_affiliate_payments.cid             = r.cid AND
              modified_affiliate_payments.tracker_id      = trackers.id AND
              modified_affiliate_payments.anid            = r.an_id AND
              modified_affiliate_payments.date_of_payment = r.transaction_date
            LEFT JOIN achievements ON
              achievements.cid                = r.cid AND
              achievements.tracker_id         = trackers.id AND
              achievements.anid               = r.an_id AND
              achievements.date_of_completion = r.transaction_date
            LEFT JOIN bonuses ON
              bonuses.username = r.username AND
              bonuses.cid      = r.cid AND
              bonuses.date     = r.transaction_date
            LEFT JOIN modified_daily_statistics_players ON
              modified_daily_statistics_players.cid = r.cid AND
              modified_daily_statistics_players.serial_id = COALESCE(history_of_players_changes.serial_id, r.serial_id)-- AND
              --daily_statistics_players.serial_id = r.serial_id AND
              --daily_statistics_players.anid      = r.an_id
          --WHERE r.username = 'Tankovskiy13'
          #{date_range}
        ) AS result
    SQL
  end

  def self.drop_view_sql months=ProcessingStatusMonth.all
    months.all.each do |psm|
      materilize_view_name = psm.months.strftime('modified_daily_players_statistics_p%Y_%m')
      "DELETE #{materilize_view_name}"
    end.join('; ')
  end
end
