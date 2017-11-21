defmodule ConnectFour.Board do
  use Supervisor

  @registered_name ConnectFourBoard
  @last_row 6
  @last_column 7

  def start_link do
    Supervisor.start_link(__MODULE__, :no_args, [name: @registered_name])
  end

  def init(:no_args) do
    children =
      for t <- spaces do
        worker(ConnectFour.Space, [t], id: t)
      end

      supervise(children, strategy: :one_for_one)
  end

  def place_token(player, column) do
    if is_full?(column) do
      :column_full
    else
      first_empty(column)
      |> agent_name(column)
      |> Process.whereis
      |> Agent.update(fn _state -> player end)
  
      :move_accepted
    end
  end

  def is_full?(column) do
    agent_name(@last_row, column)
    |> Process.whereis
    |> Agent.get(&(&1))
    |> (&(&1 != Empty)).()
  end

  def first_empty(column) do
    first_empty(1, column)
  end

  def first_empty(row, column) do
    if empty_space?(row, column) do
      row
    else
      first_empty(row + 1, column)
    end
  end

  def empty_space?(row, column) do
    agent_name(row, column)
    |> Process.whereis
    |> Agent.get(&(&1))
    |> is_empty?
  end

  def is_empty?(val) do
    val == Empty
  end

  def spaces do
    for row <- 1..@last_row, column <- 1..@last_column, do: {row, column}
  end

  def print do
    for row <- @last_row..1, do: print_columns(row)
  end

  def print_columns(row) do
    for col <- 1..@last_column, do: print_space(row, col)
    IO.write "\n"
  end

  def print_space(row, col) do
    agent_name(row, col)
    |> Process.whereis
    |> Agent.get(fn x -> x end)
    |> convert_for_display
    |> IO.write
  end

  def convert_for_display(agent_state) do
    case agent_state do
      Empty -> "."
      :red -> "R"
      :black -> "B"
      _ -> "?"
    end
  end

  def agent_name(row, col) do
    String.to_atom("R" <> Integer.to_string(row) <> "C" <> Integer.to_string(col))
  end
end