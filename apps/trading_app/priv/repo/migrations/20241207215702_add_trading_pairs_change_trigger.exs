defmodule TradingApp.Repo.Migrations.AddTradingPairsChangeTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_trading_pairs_changes()
    RETURNS trigger AS $$
    DECLARE
      current_row RECORD;
    BEGIN
      IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        current_row := NEW;
      ELSE
        current_row := OLD;
      END IF;
    PERFORM pg_notify(
        'trading_pairs_changes',
        json_build_object(
          'table', TG_TABLE_NAME,
          'type', TG_OP,
          'id', current_row.id,
          'data', row_to_json(current_row)
        )::text
    );

    RETURN current_row;

    END;

    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER notify_trading_pairs_changes_trg
    AFTER INSERT OR UPDATE OR DELETE
    ON trading_pairs
    FOR EACH ROW
    EXECUTE PROCEDURE notify_trading_pairs_changes();
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS notify_trading_pairs_changes_trg ON trading_pairs;")
    execute("DROP FUNCTION IF EXISTS notify_trading_pairs_changes();")
  end
end
