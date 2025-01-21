defmodule TradingApp.TransactionSlotsTest do
  use TradingApp.RepoCase

  import TradingApp.TestHelpers
  alias TradingApp.TransactionSlots

  describe "create_changeset/2" do
    test "valid create_changeset with required fields" do
      attrs = %{trade_coin: "FDUSD", budget: 10.14, trades_done: 777, status: "ready"}
      changeset = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      assert changeset.valid?
    end

    test "invalid create_changeset when trade_coin field is missing" do
      attrs = %{budget: 10.14, trades_done: 777, status: "ready"}
      changeset = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      refute changeset.valid?
      assert %{trade_coin: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid create_changeset when budget field is missing" do
      attrs = %{trade_coin: "FDUSD", trades_done: 777, status: "ready"}
      changeset = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      refute changeset.valid?
      assert %{budget: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid create_changeset when trades_done field is missing" do
      attrs = %{trade_coin: "FDUSD", budget: 10.14, status: "ready"}
      changeset = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      refute changeset.valid?
      assert %{trades_done: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid create_changeset when status field is missing" do
      attrs = %{trade_coin: "FDUSD", budget: 10.14, trades_done: 777}
      changeset = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      refute changeset.valid?
      assert %{status: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_changset/2" do
    test "valid update_changeset with required fields" do
      attrs = %{trade_coin: "FDUSD", budget: 10.14, trades_done: 777, status: "ready"}
      transaction_slot = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      updated_attrs = %{budget: 77.77, trades_done: 2, status: "busy"}

      updated_transaction_slot =
        TransactionSlots.update_changeset(transaction_slot, updated_attrs)

      updated_attrs_2 = %{budget: 77.77, trades_done: 2, status: "blocked"}

      updated_transaction_slot_2 =
        TransactionSlots.update_changeset(transaction_slot, updated_attrs_2)

      assert updated_transaction_slot.valid?
      assert updated_transaction_slot_2.valid?

      assert Ecto.Changeset.apply_changes(updated_transaction_slot).budget == 77.77
      assert Ecto.Changeset.apply_changes(updated_transaction_slot).trades_done == 2
      assert Ecto.Changeset.apply_changes(updated_transaction_slot).status == "busy"

      assert Ecto.Changeset.apply_changes(updated_transaction_slot_2).budget == 77.77
      assert Ecto.Changeset.apply_changes(updated_transaction_slot_2).trades_done == 2
      assert Ecto.Changeset.apply_changes(updated_transaction_slot_2).status == "blocked"
    end

    test "invalid update_changeset when budget field is missing" do
      attrs = %{trade_coin: "FDUSD", budget: 10.14, trades_done: 777, status: "ready"}
      transaction_slot = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      updated_attrs = %{budget: nil, trades_done: 2, status: "busy"}

      updated_transaction_slot =
        TransactionSlots.update_changeset(transaction_slot, updated_attrs)

      refute updated_transaction_slot.valid?
    end

    test "invalid update_changeset when trades_done field is missing" do
      attrs = %{trade_coin: "FDUSD", budget: 10.14, trades_done: 777, status: "ready"}
      transaction_slot = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      updated_attrs = %{budget: 77.77, trades_done: nil, status: "busy"}

      updated_transaction_slot =
        TransactionSlots.update_changeset(transaction_slot, updated_attrs)

      refute updated_transaction_slot.valid?
    end

    test "invalid update_changeset when status field is missing" do
      attrs = %{trade_coin: "FDUSD", budget: 10.14, trades_done: 777, status: "ready"}
      transaction_slot = TransactionSlots.create_changeset(%TransactionSlots{}, attrs)

      updated_attrs = %{budget: 77.77, trades_done: 2, status: nil}

      updated_transaction_slot =
        TransactionSlots.update_changeset(transaction_slot, updated_attrs)

      refute updated_transaction_slot.valid?
    end
  end

  describe "create_new_transaction_slot/2" do
    test "successfully creates a new transaction slot" do
      {:ok, transaction_slot} = TransactionSlots.create_new_transaction_slot(100.0, "BTC")

      assert transaction_slot.trade_coin == "BTC"
      assert transaction_slot.budget == 100.0
      assert transaction_slot.trades_done == 0
      assert transaction_slot.status == "ready"
    end
  end

  describe "update_transaction_slot/2" do
    test "successfully updates a transaction slot" do
      {:ok, transaction_slot} = TransactionSlots.create_new_transaction_slot(100.0, "BTC")
      updated_attrs = %{budget: 50.0, trades_done: +1, status: "busy"}

      {:ok, updated_slot} =
        TransactionSlots.update_transaction_slot(transaction_slot.id, updated_attrs)

      assert updated_slot.budget == 50.0
      assert updated_slot.trades_done == 1
      assert updated_slot.status == "busy"
    end
  end

  describe "fetch_free_transaction_slot/1" do
    test "fetches a free transaction slot if available" do
      TransactionSlots.create_new_transaction_slot(100.0, "BTC")

      {:ok, free_slot} = TransactionSlots.fetch_free_transaction_slot("BTC")
      assert free_slot.status == "ready"
    end

    test "returns error if no free slot is available" do
      assert {:error, "No free transaction slot for BTC"} =
               TransactionSlots.fetch_free_transaction_slot("BTC")
    end

    test "blocks a slot with zero budget" do
      {:ok, transaction_slot} = TransactionSlots.create_new_transaction_slot(0.0, "BTC")
      {:error, message} = TransactionSlots.fetch_free_transaction_slot("BTC")

      assert message == "Transaction slot id: #{transaction_slot.id} blocked!"
    end
  end
end
