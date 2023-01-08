pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Game contract

contract Game {
    using SafeMath for uint;

    struct Player {
        address addr;
        bool isWhite;
    }

    enum GameState {
        CREATED,
        ACTIVE,
        FINISHED
    }

    address public whitePlayer;
    address public blackPlayer;
    GameState public state;
    uint public startTime;
    uint public timeLimit;
    bytes32 public whiteSeed;
    bytes32 public blackSeed;
    Board public board;

    constructor() public {
        timeLimit = 3 minutes;
    }

    function createGame(bytes32 seed) public {
        require(state == GameState.CREATED, "Game has already been created");
        whitePlayer = msg.sender;
        whiteSeed = seed;
        state = GameState.ACTIVE;
        startTime = now;
        board = new Board(); 
    }

    function joinGame(bytes32 seed) public {
        require(state == GameState.ACTIVE, "Game has not been created or is already finished");
        blackPlayer = msg.sender;
        blackSeed = seed;
        if (keccak256(seed) < keccak256(whiteSeed)) {
            (whitePlayer, blackPlayer) = (blackPlayer, whitePlayer);
        }
    }

    function submitMove(uint8 x, uint8 y) public {
        require(state == GameState.ACTIVE, "Game has not been created or is already finished");
        require(msg.sender == whitePlayer || msg.sender == blackPlayer, "Sender is not a player in this game");
        require(board.placeStone(x, y, msg.sender), "Invalid move");
        startTime = now;
        emit onMove(x, y, msg.sender == whitePlayer);
        if (board.isFinished()) {
            state = GameState.FINISHED;
        }
    }

    function resign() public {
        require(state == GameState.ACTIVE, "Game has not been created or is already finished");
        require(msg.sender == whitePlayer || msg.sender == blackPlayer, "Sender is not a player in this game");
        state = GameState.FINISHED;
    }

    function getGameState() public view returns (GameState) {
        return state;
    }

    function getBoard() public view returns (Board.BoardState memory) {
        return board.getState();
    }

    function getWhitePlayer() public view returns (Player memory) {
        return Player(whitePlayer, true);
    }

    function getBlackPlayer() public view returns (Player memory) {
        return Player(blackPlayer, false);
    }

    event onMove(uint8 x, uint8 y, bool isWhite);
}

// Board contract

contract Board {
    struct Stone {
        bool isWhite;
        uint8 x;
        uint8 y;
    }

    struct Group {
            Stone[] stones;
            uint8 liberties;
        }

    struct BoardState {
        Stone[19][19] stones;
        uint whiteScore;
        uint blackScore;
    }

    Stone[19][19] public stones;
    mapping(uint => Group) public groups;
    uint public whiteScore;
    uint public blackScore;

    function placeStone(uint8 x, uint8 y, address player) public returns (bool) {
        require(stones[x][y].isWhite == false, "Intersection is already occupied");
        stones[x][y].isWhite = player == Game.whitePlayer();
        stones[x][y].x = x;
        stones[x][y].y = y;

        // Add stone to a new group
        groups[uint(stones[x][y])] = Group(stones[x][y], countLiberties(stones[x][y]));

        // Merge with adjacent groups
        Group memory group = groups[uint(stones[x][y])];
        Group[] memory adjacentGroups;
        for (uint8 i = -1; i <= 1; i++) {
            for (uint8 j = -1; j <= 1; j++) {
                if (i == 0 && j == 0) continue;
                if (x + i < 0 || x + i > 18 || y + j < 0 || y + j > 18) continue;
                if (stones[x+i][y+j].isWhite == stones[x][y].isWhite) {
                    adjacentGroups.push(groups[uint(stones[x+i][y+j])]);
                }
            }
        }
        for (uint i = 0; i < adjacentGroups.length; i++) {
            mergeGroups(group, adjacentGroups[i]);
        }

        // Remove liberties from opposite color groups
        for (uint8 i = -1; i <= 1; i++) {
            for (uint8 j = -1; j <= 1; j++) {
                if (i == 0 && j == 0) continue;
                if (x + i < 0 || x + i > 18 || y + j < 0 || y + j > 18) continue;
                if (stones[x+i][y+j].isWhite != stones[x][y].isWhite) {
                    Group memory oppositeGroup = groups[uint(stones[x+i][y+j])];
                    oppositeGroup.liberties = oppositeGroup.liberties.sub(1);
                    if (oppositeGroup.liberties == 0) {
                        removeGroup(oppositeGroup);
                    }
                }
            }
        }

        return true;
    }

    function getState() public view returns (BoardState memory) {
        BoardState memory state;
        state.stones = stones;
        state.whiteScore = whiteScore;
        state.blackScore = blackScore;
        return state;
    }

    function isFinished() public view returns (bool) {
        return whiteScore + blackScore == 19 * 19;
    }

    function calculateScore() public {
        whiteScore = 0;
        blackScore = 0;
        for (uint i = 0; i < 19; i++) {
            for (uint j = 0; j < 19; j++) {
                if (stones[i][j].isWhite) {
                    whiteScore = whiteScore.add(1);
                } else if (!stones[i][j].isWhite) {
                    blackScore = blackScore.add(1);
                }
            }
        }
    }

    function countLiberties(Stone stone) private view returns (uint8) {
        uint8 liberties = 0;
        for (uint8 i = -1; i <= 1; i++) {
            for (uint8 j = -1; j <= 1; j++) {
                if (i == 0 && j == 0) continue;
                if (stone.x + i < 0 || stone.x + i > 18 || stone.y + j < 0 || stone.y + j > 18) continue;
                if (!stones[stone.x+i][stone.y+j].isWhite) {
                    liberties = liberties.add(1);
                }
            }
        }
        return liberties;
    }

    function mergeGroups(Group memory a, Group memory b) private {
        if (a.stones.length < b.stones.length) {
            (a, b) = (b, a);
        }
        for (uint i = 0; i < b.stones.length; i++) {
            a.stones.push(b.stones[i]);
        }
        delete groups[uint(b.stones[0])];
        a.liberties = a ;
    }
}

