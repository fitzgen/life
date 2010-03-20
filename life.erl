%% JOHN CONWAY'S GAME OF LIFE
%% By Nick Fitzgerald <http://fitzgeraldnick.com/>
%% MIT Licensed

%% Preface

%% All pre-processor defined ?CONSTANTS are meant to be tweaked as you see fit.

%% Performance was not the goal of this implementation; legibility and clarity
%% were.

%% John Conway'S Game Of Life

-module(life).
-export([start/0]).

%% The Game of Life consists of cells on a board. The board is laid out as a
%% ?BOARD_SIZE by ?BOARD_SIZE grid of cells. Modify ?BOARD_SIZE for the best fit
%% for your resolution and terminal size.

-define(BOARD_SIZE, 25).

%% The cells must have one of two states at all times: alive or dead. For
%% simplicity, we can represent the board as a list of cells, if the cells keep
%% track of their own coordinates on the XY plane, in addition to their
%% alive/dead state.

-record(cell, {
          x,
          y,
          alive
         }).

%% Cells are controlled by very simple rules that are dictated by the state of
%% it's neighbors. We define it's neighbors as the eight cells that surround it
%% horizontally, vertically, and diagonally.

is_neighbor(C, Cell) ->
    Delta_X = abs(C#cell.x - Cell#cell.x),
    Delta_Y = abs(C#cell.y - Cell#cell.y),
    (Delta_X =< 1) andalso (Delta_Y =< 1) andalso (C =/= Cell).

neighbors(Cell, Board) ->
    lists:filter(fun(C) -> is_neighbor(C, Cell) end,
                 Board).

%% A living cell will die from loneliness or overcrowding. A live cell is lonely
%% when there are fewer than two live cells directly next to it. A live cell
%% gets overcrowded when there are four or more live cells next to
%% it. Otherwise, the cell will continue to live. A dead cell will be born again
%% if it has exactly 3 live neighbors, otherwise it will stay dead.

should_die(Cell, Board) ->
    Neighbors = neighbors(Cell, Board),
    Live_Neighbors = length(lists:filter(fun(C) -> C#cell.alive =:= true end,
                                         Neighbors)),
    case Cell#cell.alive of
        true -> (Live_Neighbors < 2) orelse (Live_Neighbors > 3);
        false -> Live_Neighbors =/= 3
    end.

should_live(Cell, Board) ->
    not should_die(Cell, Board).

%% We get the next generation of cells on the board by applying the rules of
%% Life to this board and gathering the results. Note that the rules are always
%% applied with the last generation's board defining which cells are alive or
%% dead. As Wikipedia puts it, "each generation is a pure function of the one
%% before".

next_generation(Board) ->
    lists:map(fun(C) ->
                      #cell{ x = C#cell.x,
                             y = C#cell.y,
                             alive = should_live(C, Board)
                            }
              end,
              Board).

%% But what are the origins of life? How is the very first board created? In
%% this implementation, we will say that each cell has a random chance to be
%% spontaneously intialized as alive. We can define that chance as approximately
%% 1/?LIFE_DENOMINATOR.

-define(LIFE_DENOMINATOR, 6).

should_cell_init_alive() ->
    random:uniform(?LIFE_DENOMINATOR) =:= 1.

init_board() ->
    init_board(?BOARD_SIZE, ?BOARD_SIZE, []).

init_board(0, 0, Board) ->
    [#cell{ x = 0,
            y = 0,
            alive = should_cell_init_alive()
           } | Board];
init_board(X_Rem, 0, Board) ->
    init_board(X_Rem - 1,
               ?BOARD_SIZE,
               [#cell{ x = X_Rem,
                       y = 0,
                       alive = should_cell_init_alive()
                      } | Board]);
init_board(X_Rem, Y_Rem, Board) ->
    init_board(X_Rem,
               Y_Rem - 1,
               [#cell{ x = X_Rem,
                       y = Y_Rem,
                       alive = should_cell_init_alive()
                      } | Board]).

%% However, it isn't fun to play God if we are blind to the events of our
%% world. I will let asterisks represent cells that are alive, and blank spaces
%% for representing the dead cells. Visually representing the board is just a
%% matter of turning our list of cells back in to the grid of rows and columns
%% that it abstracts.

render(Cell) when is_record(Cell, cell) andalso Cell#cell.alive ->
    io:format(" *");
render(Cell) when is_record(Cell, cell) andalso (not Cell#cell.alive) ->
    io:format("  ");
render(Board) when is_list(Board) ->
    io:format("~n"),
    render(0, 0, Board).

render(?BOARD_SIZE, ?BOARD_SIZE, _) ->
    io:format("~n");
render(X, Y, Board) when X =:= ?BOARD_SIZE ->
    render(get_cell(X, Y, Board)),
    io:format("~n"),
    render(0, Y + 1, Board);
render(X, Y, Board) ->
    render(get_cell(X, Y, Board)),
    render(X + 1, Y, Board).

get_cell(X, Y, Board) ->
    [Res] = lists:filter(fun(Cell) ->
                                 (Cell#cell.x =:= X) andalso (Cell#cell.y =:= Y)
                         end,
                         Board),
    Res.

%% After Life has started, it doesn't stop. We need a construct that will
%% enforce this and show us each generation's change. You may want to modify the
%% ?TIMEOUT (milliseconds) before each new generation is calculated and rendered
%% so that you can best see the patterns emarge.

-define(TIMEOUT, 750).

start() ->
    B = init_board(),
    loop(B).

loop(Board) ->
    render(Board),
    sleep(?TIMEOUT),
    loop(next_generation(Board)).

sleep(Ms) ->
    receive
    after Ms ->
        ok
    end.

%% That's it! To begin the Game, open an Erlang shell and compile this
%% file. Then run `life:start().'
