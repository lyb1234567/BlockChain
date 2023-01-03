pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract Game
{
   using SafeMath for uint;

    // Enum for game states
    enum GameState { Pending, InProgress, Completed }

    // Struct for players
    struct Player {
        address addr;
        bool isWhite;
        string name;
    }

    // Struct for moves
    struct Move {
        address player;
        uint x;
        uint y;
        bool isLegal;
    }

    GameState public gameState;
    Player[] public players;
    uint public turnCounter;
    address public currentPlayer;
    Board public board;
    Move[] public moves;

     constructor(address player1, address player2) public 
     {
        players.push(Player(player1, true,"Player1"));
        players.push(Player(player2, false,"Player2"));
        gameState = GameState.Pending;
        turnCounter = 0;
        board = new Board();
    }

     function startGame() public 
     {
        require(gameState == GameState.Pending, "Game has already started");
        require(players[0].addr == msg.sender, "Only first player can start game");

        gameState = GameState.InProgress;
        currentPlayer = players[0].addr;

        // Randomly determine who gets to play white
        if (uint(keccak256(abi.encodePacked(now))) % 2 == 1) 
        {
            swap(players[0],players[1]);
            // Initialize the game board
        }
        board.initializeBoard();
     }
}

}