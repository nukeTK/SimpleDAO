//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GovernanceToken.sol";

contract GovernorContract is AccessControl {
    struct Proposals {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        address proposer;
        address reciver;
        uint256 voteFor;
        uint256 voteAganist;
        bool voteEnd;
        bool isQueued;
        bool isExecuted;
        bool isCancel;
    }
    struct Voters {
        uint256 id;
        address[] voteForAdd;
        address[] voteAganistAdd;
    }
    GovernanceToken public token;
    bytes32 public constant MEMBER = keccak256("MEMBER");
    bytes32 public constant DELEGATE = keccak256("DELEGATE");

    uint32 constant votingPeriod = 500;
    uint32 constant votingDelay = 1;
    mapping(uint256 => Voters) private voting;
    mapping(uint256 => Proposals) private proposal;
    mapping(address => bool) private isVoted;
    uint256 public numProposal = 0;

    constructor(address _token) {
        token = GovernanceToken(_token);
    }

    modifier onlyMembers() {
        require(hasRole(MEMBER, msg.sender), "You are not Authorized");
        _;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        address rec
    ) public onlyMembers {
        require(token.balanceOf(msg.sender) >= 100, "Not enough Tokens");
        numProposal++;
        proposal[numProposal] = Proposals(
            numProposal,
            _title,
            _description,
            block.timestamp + votingDelay,
            block.timestamp + votingPeriod,
            msg.sender,
            rec,
            0,
            0,
            false,
            false,
            false,
            false
        );
    }

    function startVotes(uint256 _proposalId, uint256 decision)
        public
        onlyMembers
    {
        require(token.balanceOf(msg.sender) >= 50, "Not enough Tokens");
        Proposals storage _proposal = proposal[_proposalId];
        require(
            block.timestamp >= _proposal.startTime,
            "Voting Not Yet Started"
        );
        if (block.timestamp > _proposal.endTime) {
            _proposal.voteEnd = true;
            require(block.timestamp > _proposal.endTime, "Voting is Closed");
        } else {
            checkVotes(msg.sender);
            require(!isVoted[msg.sender], "Already Voted");
            Voters storage _voters = voting[_proposalId];
            uint256 vote = token.getVotes(msg.sender);
            if (decision == 0) {
                //For
                _proposal.voteFor += vote;
                _voters.voteForAdd.push(msg.sender);
                isVoted[msg.sender] = true;
            } else {
                //Aganist
                _proposal.voteAganist += vote;
                _voters.voteAganistAdd.push(msg.sender);
                isVoted[msg.sender] = true;
            }
        }
    }

    function allProposals() public view returns (Proposals[] memory) {
        uint256 currentToken = 0;
        Proposals[] memory _proposal = new Proposals[](numProposal);
        for (uint256 i = 0; i < numProposal; i++) {
            uint256 currentId = i + 1;
            Proposals storage item = proposal[currentId];
            _proposal[currentToken] = item;
            currentToken += 1;
        }
        return _proposal;
    }

    function checkStatus(uint256 _proposalId) public onlyMembers {
        Proposals storage _proposal = proposal[_proposalId];
        require(
            !_proposal.isCancel && !_proposal.isExecuted,
            "Process has been completed"
        );
        require(_proposal.voteEnd, "Voting not yet Completed");
        if (_proposal.voteFor > _proposal.voteAganist)
            _proposal.isQueued = true;
        else _proposal.isCancel = true;
    }

    function executeProposal(uint256 _proposalId)
        public
        onlyMembers
        returns (bool)
    {
        Proposals storage _proposal = proposal[_proposalId];
        require(
            !_proposal.isCancel && !_proposal.isExecuted,
            "Process has been completed"
        );
        require(_proposal.isQueued, "Not queued");
        token.transfer(_proposal.reciver, 50);
        _proposal.isExecuted = true;
        _setupRole(MEMBER, _proposal.reciver);
        return true;
    }

    function setupRole() public {
        require(!hasRole(MEMBER, msg.sender), "Already Member");
        require(token.balanceOf(msg.sender) >= 50, "No enough token ");
        _setupRole(MEMBER, msg.sender);
    }

    function getStatus(uint256 _proposalId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Proposals storage _proposal = proposal[_proposalId];
        return (block.timestamp, _proposal.startTime, _proposal.endTime);
    }

    function getVoters(uint256 _proposalId)
        public
        view
        returns (
            uint256,
            address[] memory,
            address[] memory
        )
    {
        Proposals storage _proposal = proposal[_proposalId];
        Voters storage _voters = voting[_proposalId];
        uint256 totalVotes = _proposal.voteFor + _proposal.voteAganist;
        return (totalVotes, _voters.voteForAdd, _voters.voteAganistAdd);
    }

    function checkVotes(address _votee) internal view {
        address _delegatee = token.delegates(_votee);
        require(
            _delegatee == _votee,
            "You have Delegate your Vote To someone else"
        );
    }
}
