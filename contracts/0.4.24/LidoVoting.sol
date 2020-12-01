// SPDX-FileCopyrightText: 2020 Lido <info@lido.fi>

// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
pragma solidity 0.4.24;

import "@aragon/apps-voting/contracts/Voting.sol";

contract LidoVoting is Voting {
  bytes32 public constant MODIFY_VOTE_TIME_ROLE = keccak256("MODIFY_VOTE_TIME_ROLE");

  event ChangeVoteTime(uint64 voteTime);

  /**
    * @notice Change vote time to `_voteTime` seconds
    * @param _voteTime Seconds that a vote will be open for token holders to vote
    */
    function changeVoteTime(uint64 _voteTime)
        external
        authP(MODIFY_VOTE_TIME_ROLE, arr(uint256(_voteTime), uint256(voteTime)))
    {
        voteTime = _voteTime;
        emit ChangeVoteTime(_voteTime);
    }
}
