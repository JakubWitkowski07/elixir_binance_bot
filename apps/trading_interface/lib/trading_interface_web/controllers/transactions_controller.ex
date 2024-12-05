defmodule TradingInterfaceWeb.TransactionsController do
  use TradingInterfaceWeb, :controller

  alias TradingApp.Transactions

  def index(conn, _params) do
    transactions = Transactions.get_pending_transatcions()
    render(conn, :index, transactions: transactions)
  end
end
