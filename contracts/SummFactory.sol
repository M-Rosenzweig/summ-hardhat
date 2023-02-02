// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SummTerms.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SummFactory is Ownable {
    address[] public deployedSumms;
    address payable summFoundation;

    event NewSumm(address indexed _contractAddress);

    constructor(address payable _summFoundation) {
        summFoundation = _summFoundation;
    }

    function createSummTerms(
        address payable _opponent,
        uint _softOffers,
        uint _firmOffers,
        uint _softRange,
        uint _firmRange,
        uint _penaltyPercent
    ) public {
        address newSummTerms = address(
            new SummTerms(
                payable(msg.sender),
                _opponent,
                _softOffers,
                _firmOffers,
                _softRange,
                _firmRange,
                _penaltyPercent,
                summFoundation
            )
        );
        deployedSumms.push(newSummTerms);

        emit NewSumm(newSummTerms);
    }

    function changeSummFoundation(
        address payable _updatedSummFoundation
    ) public onlyOwner {
        summFoundation = _updatedSummFoundation;
    }

    function getDeployedSumms() public view returns (address[] memory) {
        return deployedSumms;
    }
}
