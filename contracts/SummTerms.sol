// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "hardhat/console.sol";
import "./FirmOffers.sol";
import "./SoftOffers.sol";

error SummTerms__MustBeOpponent(address _who); 
error SummTerms__SoftOfferCapAmountRange0_10(uint _amount); 
error SummTerms__FirmOfferCapAmountRange10(uint _amount); 
error SummTerms__PartiesMustBeDifferentWallets(); 
error SummTerms__PenaltyPercentRange(); 

// address initalizedSumm = address(new Summ(creator, opponent, totalSoftOffersCap, totalFirmOffersCap, softRange, firmRange, penaltyPercent, summFoundation ));



contract SummTerms {
    event TermsResponse(address _initializedSumm, bool _created);
    event TestEvent(uint _randomNumber);

    address[] public createdSumms;

    address payable immutable creator;
    address payable immutable opponent;

    uint public totalSoftOffersCap;
    uint public totalFirmOffersCap;
    uint public softRange;
    uint public firmRange;
    uint public penaltyPercent;
    bool public termsStatus;

    address payable immutable summFoundation;

    modifier onlyOpponent() {
        if(msg.sender != opponent) revert SummTerms__MustBeOpponent(msg.sender); 
    
        _;
    }

    constructor(
        address payable _creator,
        address payable _opponent,
        uint _totalSoftOffersCap,
        uint _totalFirmOffersCap,
        uint _softRange,
        uint _firmRange,
        uint _penaltyPercent,
        address payable _summFoundation
    ) {
        if(_totalSoftOffersCap > 10 || _totalSoftOffersCap < 0){
            revert SummTerms__SoftOfferCapAmountRange0_10(_totalSoftOffersCap); 
        }
        if(_totalFirmOffersCap > 10) {
            revert SummTerms__FirmOfferCapAmountRange10(_totalFirmOffersCap); 
        }
        if(_opponent == _creator){
            revert SummTerms__PartiesMustBeDifferentWallets(); 
        }
        require(_softRange > 0 && _softRange < 40);
        require(_firmRange > 0 && _firmRange < 40);
        if(_penaltyPercent < 0 || _penaltyPercent > 20){
            revert SummTerms__PenaltyPercentRange(); 
        }
        creator = _creator;
        opponent = _opponent;
        totalSoftOffersCap = _totalSoftOffersCap;
        totalFirmOffersCap = _totalFirmOffersCap;
        softRange = _softRange;
        firmRange = _firmRange;
        penaltyPercent = _penaltyPercent;
        summFoundation = _summFoundation;
    }

    function respondToTerms(bool _response) public onlyOpponent {
        if (_response == true) {
            address initalizedSumm = address(new FirmOffers(address(this)));
            emit TermsResponse(initalizedSumm, true);
            emit TestEvent(613);
            termsStatus = true;
            createdSumms.push(initalizedSumm);
        } else {
            // console.log("before events");
            emit TermsResponse(
                0x0000000000000000000000000000000000000000,
                false
            );
            emit TestEvent(770); // these events are not working and I dont know why.. maybe gas limit reached???
            // console.log("after events Moish");
            // console.log("TestEvent", 770);
        }
    }

    function getSummary() public view returns(address payable, address payable, uint, uint, uint, uint, uint, bool){
        return(
            creator, 
            opponent, 
            totalSoftOffersCap, 
            totalFirmOffersCap, 
            softRange, 
            firmRange, 
            penaltyPercent, 
            termsStatus
        ); 
    }

    function getCreator() public view returns (address payable) {
        return creator;
    }

    function getOpponent() public view returns (address payable) {
        return opponent;
    }

    function getSummFoundation() public view returns (address payable) {
        return summFoundation;
    }
}
