// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SummTerms.sol";
import "hardhat/console.sol";

contract Summ {
    event SoftOfferGiven(
        address _who,
        uint _number,
        bool _bothGivenAndProcessed
    );
    event InRange(bool _readyToAccept, bool _softRoundActive);
    event OfferAccepted(
        address _who,
        bool _bothPartiesAccept,
        uint _finalCompromisedAmount,
        bool _resolved
    );
    event OfferDeclined(address _who, bool _softOfferRoundsActive);
    event MediumNumberAndPenaltyVariablesSet(bool _set);
    event FirmOfferGiven(
        address _who,
        uint _number,
        bool _bothGivenAndProcessed
    );
    event FirmOfferStatus(
        bool _withinRange,
        uint _giverOffer,
        uint _receiverOffer,
        uint _percentageDiff,
        uint amountDiff,
        uint _compromiseAmount,
        uint _finalFirmAmount,
        bool _resolved,
        bool _penalties
    );
    event PenaltyGiven(
        address _whoPaid,
        address _whoReceived,
        uint _penaltyAmount
    );
    event AmountDistanceTie(bool _tie);
    event TakeItOrLeaveItOfferGiven(address _who, bool _given, uint _amount);
    event TakeItOrLeaveItResponse(
        address _whoResponded,
        bool _accepted,
        uint _amount
    );

    SummTerms internal summTerms;

    address payable public creator;
    address payable public opponent;
    address payable private summFoundation;

    mapping(address => uint) private balance;

    uint public totalSoftOffersCap;
    uint public totalFirmOffersCap;
    uint public softRange;
    uint public firmRange;
    uint public penaltyPercent;

    bool public firstRoundSafe;

    uint private culumativeGiverAmount;
    uint private culumativeReceiverAmount;

    uint public mediumNumber;
    uint public penalty;

    bool public resolved; // maybe change these two states to an Enum (resolved and softRoundActive) // pastFirstFirmOffers and softRoundCurrentlyActive modifiers...
    bool public softRoundActive = true;

    uint public currentSoftGiverOffer;
    uint public currentSoftReceiverOffer;

    uint public currentFirmGiverOffer;
    uint public currentFirmReceiverOffer;

    uint private finalSoftOffer;
    uint private finalFirmOffer;

    bool private creatorTakeItOrLeaveItGiven;
    uint public finalTakeItOrLeaveItAmount;
    bool private creatorTakeItOrLeaveItRespondedTo;

    bool private receiverTakeOrLeaveRequestGiven;
    uint public finalTakeOrLeaveRequestAmount;
    bool private receiversTakeOrLeaveRespondedTo;

    struct SoftReceiverOffer {
        uint amount;
        uint number;
        bool given;
        bool accepted;
    }

    struct SoftGiverOffer {
        uint amount;
        uint number;
        bool given;
        bool accepted;
    }

    struct FirmReceiverOffer {
        uint amount;
        uint number;
        bool given;
    }

    struct FirmGiverOffer {
        uint amount;
        uint number;
        bool given;
    }

    SoftReceiverOffer[] private softReceiverOffers;
    SoftGiverOffer[] private softGiverOffers;
    FirmReceiverOffer[] private firmReceiverOffers;
    FirmGiverOffer[] private firmGiverOffers;

    modifier onlyCreator() {
        require(
            msg.sender == creator,
            "Only the contract creator can call this function."
        );
        _;
    }

    modifier onlyOpponent() {
        require(
            msg.sender == opponent,
            "Only the contract opponent can call this function."
        );
        _;
    }

    modifier unresolved() {
        require(resolved == false);
        _;
    }

    modifier sameOfferNumberAndBothGivenUnresolved() {
        require(currentSoftGiverOffer == currentSoftReceiverOffer);
        require(
            softReceiverOffers[currentSoftReceiverOffer - 1].given == true &&
                softGiverOffers[currentSoftGiverOffer - 1].given == true
        );
        require(resolved == false);
        _;
    }

    modifier softRoundCurrentlyActive() {
        require(softRoundActive == true);
        _;
    }

    modifier pastFirstFirmOffers() {
        require(currentFirmGiverOffer > 0 && currentFirmReceiverOffer > 0);
        _;
    }

    constructor(address _summTermsAddress) {
        summTerms = SummTerms(_summTermsAddress);

        creator = summTerms.getCreator();
        opponent = summTerms.getOpponent();
        totalSoftOffersCap = summTerms.totalSoftOffersCap();
        totalFirmOffersCap = summTerms.totalFirmOffersCap();
        softRange = summTerms.softRange();
        firmRange = summTerms.firmRange();
        penaltyPercent = summTerms.penaltyPercent();
        summFoundation = summTerms.getSummFoundation();
    }

    function getSummary()
        public
        view
        returns (uint, uint, address, address, uint, uint, uint, bool)
    {
        return (
            totalSoftOffersCap,
            totalFirmOffersCap,
            creator,
            opponent,
            softRange,
            firmRange,
            penaltyPercent,
            resolved
        );
    }

    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }

    function checkBalance() public view returns (uint) {
        return balance[msg.sender];
    }

    function fullWithdrawl() public {
        if (
            msg.sender == creator &&
            creatorTakeItOrLeaveItGiven == true &&
            creatorTakeItOrLeaveItRespondedTo == false
        ) {
            uint availableWithdrawAmount = (balance[creator] - penalty);
            //  require(availableWithdrawAmount > penalty);
            balance[creator] -= (availableWithdrawAmount + penalty);
            balance[summFoundation] += penalty;
            creator.transfer(availableWithdrawAmount);
            creatorTakeItOrLeaveItRespondedTo = true;
        } else if (
            msg.sender == opponent &&
            receiverTakeOrLeaveRequestGiven == true &&
            receiversTakeOrLeaveRespondedTo == false
        ) {
            uint availableWithdrawAmount = (balance[opponent] - penalty);
            balance[opponent] -= (availableWithdrawAmount + penalty);
            balance[summFoundation] += penalty;
            opponent.transfer(availableWithdrawAmount);
            receiversTakeOrLeaveRespondedTo = true;
        } else {
            uint amountToWithdraw = balance[msg.sender];
            balance[msg.sender] -= amountToWithdraw;
            payable(msg.sender).transfer(amountToWithdraw);
        }
    }

    function partialWithdraw(uint _amount) public {
        if (
            msg.sender == creator &&
            creatorTakeItOrLeaveItGiven == true &&
            creatorTakeItOrLeaveItRespondedTo == false
        ) {
            require(
                balance[creator] >= (_amount + penalty),
                "you dont have enough to pay the penalty and remove that amount"
            );
            balance[creator] -= (_amount + penalty);
            balance[summFoundation] += penalty;
            creator.transfer(_amount);
            creatorTakeItOrLeaveItRespondedTo = true;
        } else if (
            msg.sender == opponent &&
            receiverTakeOrLeaveRequestGiven == true &&
            receiversTakeOrLeaveRespondedTo == false
        ) {
            require(
                balance[opponent] >= (_amount + penalty),
                "you dont have enough to pay the penalty and remove that amount"
            );
            balance[opponent] -= (_amount + penalty);
            balance[summFoundation] += penalty;
            opponent.transfer(_amount);
            receiversTakeOrLeaveRespondedTo = true;
        } else {
            require(_amount <= balance[msg.sender], "not enough funds");
            balance[msg.sender] -= _amount;
            payable(msg.sender).transfer(_amount);
        }
    }

    // SOFT OFFERS

    function initiateSoftGiverOffer(
        uint _amount
    ) public onlyCreator softRoundCurrentlyActive {
        uint bufferAmount = (_amount * softRange) / 200;
        require(
            currentSoftGiverOffer < totalSoftOffersCap,
            "reached cap on amount of soft offers"
        );
        require(
            balance[creator] >= _amount + bufferAmount,
            "you do not have enough funds to make such an offer"
        );
        require(_amount > 0);
        currentSoftGiverOffer++;
        require(
            currentSoftGiverOffer == currentSoftReceiverOffer ||
                (currentSoftGiverOffer - 1) == currentSoftReceiverOffer,
            "you must wait until the opponent puts in their offer to initate an additonal offer"
        );

        SoftGiverOffer memory newOffer = SoftGiverOffer({
            amount: _amount,
            number: currentSoftGiverOffer,
            given: true,
            accepted: false
        });

        if (totalSoftOffersCap > 1 && currentSoftGiverOffer == 1) {
            softGiverOffers.push(newOffer);
            firstRoundSafe = true;
        } else {
            culumativeGiverAmount += _amount;
            softGiverOffers.push(newOffer);
        }

        if (
            currentSoftGiverOffer == totalSoftOffersCap &&
            currentSoftReceiverOffer == totalSoftOffersCap
        ) {
            determineMediumNumberAndPenalty(
                culumativeGiverAmount,
                culumativeReceiverAmount
            );
            emit MediumNumberAndPenaltyVariablesSet(true);
        }

        if (
            currentSoftGiverOffer == currentSoftReceiverOffer &&
            softReceiverOffers[currentSoftReceiverOffer - 1].given == true
        ) {
            processSoftOffer();
            emit SoftOfferGiven(creator, currentSoftGiverOffer, true);
        } else {
            // console.log("waiting on the opponent to make an offer");
            emit SoftOfferGiven(creator, currentSoftGiverOffer, false);
        }
    }

    function initiateSoftReceiverOffer(
        uint _amount
    ) public onlyOpponent softRoundCurrentlyActive {
        require(_amount > 0);
        require(
            currentSoftReceiverOffer < totalSoftOffersCap,
            "reached cap on amount of soft offers"
        );
        currentSoftReceiverOffer++;
        require(
            currentSoftReceiverOffer == currentSoftGiverOffer ||
                (currentSoftReceiverOffer - 1) == currentSoftGiverOffer,
            "you must wait until the creator puts in their offer to initate a new offer"
        );

        SoftReceiverOffer memory newOffer = SoftReceiverOffer({
            amount: _amount,
            number: currentSoftReceiverOffer,
            given: true,
            accepted: false
        });

        if (totalSoftOffersCap > 1 && currentSoftReceiverOffer == 1) {
            softReceiverOffers.push(newOffer);
            firstRoundSafe = true;
        } else {
            culumativeReceiverAmount += _amount;
            softReceiverOffers.push(newOffer);
        }

        if (
            currentSoftGiverOffer == totalSoftOffersCap &&
            currentSoftReceiverOffer == totalSoftOffersCap
        ) {
            determineMediumNumberAndPenalty(
                culumativeGiverAmount,
                culumativeReceiverAmount
            );
            emit MediumNumberAndPenaltyVariablesSet(true);
        }

        if (
            currentSoftGiverOffer == currentSoftReceiverOffer &&
            softGiverOffers[currentSoftGiverOffer - 1].given == true
        ) {
            processSoftOffer();
            emit SoftOfferGiven(opponent, currentSoftReceiverOffer, true);
        } else {
            emit SoftOfferGiven(opponent, currentSoftReceiverOffer, false);
        }
    }

    function processSoftOffer() private {
        uint giverOffer = (softGiverOffers[currentSoftGiverOffer - 1].amount);
        uint receiverOffer = (
            softReceiverOffers[currentSoftReceiverOffer - 1].amount
        );
        uint percentageDiff = receiverOffer > giverOffer
            ? (((receiverOffer - giverOffer) * 100) / receiverOffer)
            : (((giverOffer - receiverOffer) * 100) / giverOffer);
        uint amountDiff = receiverOffer > giverOffer
            ? receiverOffer - giverOffer
            : giverOffer - receiverOffer;
        uint compromiseAmount = (amountDiff / 2);

        if (percentageDiff <= softRange && receiverOffer > giverOffer) {
            finalSoftOffer = giverOffer + compromiseAmount;
            emit InRange(true, softRoundActive);
        } else if (percentageDiff <= softRange && giverOffer > receiverOffer) {
            finalSoftOffer = receiverOffer + compromiseAmount;
            emit InRange(true, softRoundActive);
        } else if (
            currentSoftGiverOffer == totalSoftOffersCap &&
            currentSoftReceiverOffer == totalSoftOffersCap
        ) {
            softRoundActive = false;
            emit InRange(false, softRoundActive);
            //  console.log("out of range. now moving to the firm rounds");
        } else {
            emit InRange(false, softRoundActive);
        }
    }

    function creatorAcceptSoftOffer()
        public
        payable
        onlyCreator
        sameOfferNumberAndBothGivenUnresolved
        softRoundCurrentlyActive
    {
        if (softReceiverOffers[currentSoftReceiverOffer - 1].accepted == true) {
            require(balance[creator] >= finalSoftOffer, "not enough funds");
            softGiverOffers[currentSoftGiverOffer - 1].accepted = true;
            // softGiverOffers[currentSoftGiverOffer - 1].complete = true;

            balance[creator] -= finalSoftOffer;
            balance[opponent] += finalSoftOffer;
            // transfer an NFT that says I have given X amount of funds for X debt or Item to Y address
            resolved = true;
            emit OfferAccepted(creator, true, finalSoftOffer, resolved);
        } else if (
            softReceiverOffers[currentSoftReceiverOffer - 1].accepted == false
        ) {
            softGiverOffers[currentSoftGiverOffer - 1].accepted = true;
            emit OfferAccepted(creator, false, 0, resolved);
            // console.log("waiting on opponent to accept for transfer to take place");
        }
    }

    function opponentAcceptSoftOffer()
        public
        payable
        onlyOpponent
        sameOfferNumberAndBothGivenUnresolved
        softRoundCurrentlyActive
    {
        if (softGiverOffers[currentSoftGiverOffer - 1].accepted == true) {
            require(
                balance[creator] >= finalSoftOffer,
                "creator does not have enough funds"
            );
            softReceiverOffers[currentSoftReceiverOffer - 1].accepted = true;
            //  softReceiverOffers[currentSoftReceiverOffer - 1].complete = true;

            balance[creator] -= finalSoftOffer;
            balance[opponent] += finalSoftOffer;
            // transfer an nft that says I received payment for X debt or item from Y address.
            resolved = true;
            emit OfferAccepted(opponent, true, finalSoftOffer, resolved);
        } else if (
            softGiverOffers[currentSoftGiverOffer - 1].accepted == false
        ) {
            softReceiverOffers[currentSoftReceiverOffer - 1].accepted = true;
            emit OfferAccepted(opponent, false, 0, resolved);
            //  console.log("waiting on creator to accept");
        }
    }

    function declineSoftOffer() public sameOfferNumberAndBothGivenUnresolved {
        require(
            msg.sender == creator || msg.sender == opponent,
            "you are not the creator or opponent"
        );
        if (currentSoftGiverOffer == totalSoftOffersCap) {
            softRoundActive = false;
            emit OfferDeclined(msg.sender, softRoundActive);
            //  event OfferDeclined(address _who, bool _softOfferRoundsActive);
            // console.log("offer has been declined by the ${msg.sender} and we are moving to firm offers");
        } else {
            emit OfferDeclined(msg.sender, softRoundActive);
            // msg.sender == creator ? console.log("creator declined and we can now both put in new offers") : console.log("opponent declined and we can now both put in new offers");
        }
    }

    // MEDIUM NUMBER AND PENALTY

    function determineMediumNumberAndPenalty(
        uint _culumativeGiverAmount,
        uint _culumativeReceiverAmount
    ) private {
        if (firstRoundSafe = true) {
            mediumNumber =
                (_culumativeGiverAmount + _culumativeReceiverAmount) /
                ((currentSoftGiverOffer - 1) + (currentSoftReceiverOffer - 1));
            penalty = ((mediumNumber * penaltyPercent) / 100);
        } else {
            mediumNumber =
                (_culumativeGiverAmount + _culumativeReceiverAmount) /
                (currentSoftGiverOffer * 2);
            penalty = ((mediumNumber * penaltyPercent) / 100);
        }
    }

    function revealMediumNumberAndPenalty() public view returns (uint, uint) {
        require(mediumNumber > 0 && softRoundActive == false);
        return (mediumNumber, penalty);
    }

    // FIRM OFFERS

    function initiateFirmGiverOffer(
        uint _amount
    ) public onlyCreator unresolved {
        require(
            currentFirmGiverOffer < totalFirmOffersCap,
            "reached cap on amount of firm offers"
        );
        uint bufferAmount = (_amount * firmRange) / 200;
        uint totalRequiredAmount = _amount + bufferAmount;
        require(
            balance[msg.sender] >= totalRequiredAmount,
            "you do not have enough funds to make such an offer"
        );
        require(mediumNumber > 0, "The medium Number has not been set yet");
        currentFirmGiverOffer++;
        require(
            currentFirmGiverOffer == currentFirmReceiverOffer ||
                (currentFirmGiverOffer - 1) == currentFirmReceiverOffer,
            "you must wait until the opponent puts in their offer to initate an additonal offer"
        );

        FirmGiverOffer memory newOffer = FirmGiverOffer({
            amount: _amount,
            number: currentFirmGiverOffer,
            given: true
        });
        firmGiverOffers.push(newOffer);

        if (
            currentFirmGiverOffer == currentFirmReceiverOffer &&
            firmReceiverOffers[currentFirmReceiverOffer - 1].given == true
        ) {
            processFirmOffer(totalRequiredAmount);
            emit FirmOfferGiven(creator, currentFirmGiverOffer, true);
        } else {
            emit FirmOfferGiven(creator, currentFirmGiverOffer, false);
        }
    }

    function initiateFirmReceiverOffer(
        uint _amount
    ) public onlyOpponent unresolved {
        require(currentFirmReceiverOffer <= totalFirmOffersCap);
        require(
            balance[msg.sender] >= penalty,
            "you must deposit the penalty amount to present a firm offer"
        );
        require(mediumNumber > 0, "The medium Number has not been set yet");
        require(
            currentFirmReceiverOffer <= totalFirmOffersCap,
            "reached cap on amount of firm offers"
        );
        currentFirmReceiverOffer++;
        require(
            currentFirmReceiverOffer == currentFirmGiverOffer ||
                (currentFirmReceiverOffer - 1) == currentFirmGiverOffer,
            "you must wait until the opponent puts in their offer to initate an additonal offer"
        );

        FirmReceiverOffer memory newOffer = FirmReceiverOffer({
            amount: _amount,
            number: currentFirmReceiverOffer,
            given: true
        });

        firmReceiverOffers.push(newOffer);

        if (
            currentFirmReceiverOffer == currentFirmGiverOffer &&
            firmReceiverOffers[currentFirmGiverOffer - 1].given == true
        ) {
            processFirmOffer(penalty);
            emit FirmOfferGiven(opponent, currentFirmReceiverOffer, true);
        } else {
            emit FirmOfferGiven(opponent, currentFirmReceiverOffer, false);
        }
    }

    function processFirmOffer(uint _amount) private {
        require(
            balance[opponent] >= penalty,
            " The opponent must redeposit the penalty amount for a firm offer to process"
        );
        require(
            balance[creator] >= _amount,
            "The creator does not have enough funds n the contract for the offer to process"
        );
        uint giverOffer = (firmGiverOffers[currentFirmGiverOffer - 1].amount);
        uint receiverOffer = (
            firmReceiverOffers[currentFirmReceiverOffer - 1].amount
        );
        uint percentageDiff = receiverOffer > giverOffer
            ? (((receiverOffer - giverOffer) * 100) / receiverOffer)
            : (((giverOffer - receiverOffer) * 100) / giverOffer);
        uint amountDiff = receiverOffer > giverOffer
            ? receiverOffer - giverOffer
            : giverOffer - receiverOffer;
        uint compromiseAmount = (amountDiff / 2);

        if (percentageDiff <= firmRange && receiverOffer > giverOffer) {
            finalFirmOffer = giverOffer + compromiseAmount;
            balance[creator] -= finalFirmOffer;
            balance[opponent] += finalFirmOffer;
            // transfer nft receipts
            resolved = true;
            emit FirmOfferStatus(
                true,
                giverOffer,
                receiverOffer,
                percentageDiff,
                amountDiff,
                compromiseAmount,
                finalFirmOffer,
                resolved,
                false
            );
        } else if (percentageDiff <= firmRange && giverOffer > receiverOffer) {
            finalFirmOffer = receiverOffer + compromiseAmount;
            balance[creator] -= finalFirmOffer;
            balance[opponent] += finalFirmOffer;
            // transfer nft receipts
            resolved = true;
            emit FirmOfferStatus(
                true,
                giverOffer,
                receiverOffer,
                percentageDiff,
                amountDiff,
                compromiseAmount,
                finalFirmOffer,
                resolved,
                false
            );
        } else if (percentageDiff > firmRange) {
            processFirmPenalties();
            emit FirmOfferStatus(false, 0, 0, 0, 0, 0, 0, resolved, true);
        }
    }

    function processFirmPenalties() private {
        uint giverOffer = (firmGiverOffers[currentFirmGiverOffer - 1].amount);
        uint receiverOffer = (
            firmReceiverOffers[currentFirmReceiverOffer - 1].amount
        );
        uint giverDiff = giverOffer > mediumNumber
            ? giverOffer - mediumNumber
            : mediumNumber - giverOffer;
        uint receiverDiff = receiverOffer > mediumNumber
            ? receiverOffer - mediumNumber
            : mediumNumber - receiverOffer;

        if (giverDiff > receiverDiff) {
            balance[creator] -= penalty;
            balance[opponent] += penalty;
            emit PenaltyGiven(creator, opponent, penalty);
        } else if (receiverDiff > giverDiff) {
            balance[opponent] -= penalty;
            balance[creator] += penalty;
            emit PenaltyGiven(opponent, creator, penalty);
        } else if (giverDiff == receiverDiff) {
            emit AmountDistanceTie(true);
        }
    }

    // function creatorTakeItOrLeaveIt(
    //     uint _amount
    // ) public onlyCreator unresolved pastFirstFirmOffers {
    //     require(creatorTakeItOrLeaveItGiven == false);
    //     require(balance[creator] >= _amount);
    //     finalTakeItOrLeaveItAmount = _amount;
    //     creatorTakeItOrLeaveItGiven = true;
    //     emit TakeItOrLeaveItOfferGiven(creator, true, _amount);
    // }

    // function receiverTakeItOrLeaveItResponse(
    //     bool _accept
    // ) public onlyOpponent unresolved pastFirstFirmOffers {
    //     require(creatorTakeItOrLeaveItGiven == true);

    //     if (_accept == true) {
    //         require(
    //             balance[creator] >= finalTakeItOrLeaveItAmount,
    //             "The contract creator has removed his funds and this offer is no longer availabel"
    //         );
    //         balance[creator] -= finalTakeItOrLeaveItAmount;
    //         balance[opponent] += finalTakeItOrLeaveItAmount;
    //         // transfer nft receipt
    //         resolved = true;
    //         creatorTakeItOrLeaveItRespondedTo = true;
    //         emit TakeItOrLeaveItResponse(
    //             opponent,
    //             true,
    //             finalTakeItOrLeaveItAmount
    //         );
    //     } else if (_accept == false) {
    //         require(balance[creator] >= penalty);
    //         balance[creator] -= penalty;
    //         balance[summFoundation] += penalty;
    //         creatorTakeItOrLeaveItRespondedTo = true;
    //         emit TakeItOrLeaveItResponse(opponent, false, 0);
    //     }
    // }

    // function receiverTakeOrLeave(
    //     uint _amount
    // ) public onlyOpponent unresolved pastFirstFirmOffers {
    //     require(receiverTakeOrLeaveRequestGiven == false);
    //     require(balance[creator] >= penalty);
    //     finalTakeOrLeaveRequestAmount = _amount;
    //     receiverTakeOrLeaveRequestGiven = true;
    //     emit TakeItOrLeaveItOfferGiven(opponent, true, _amount);
    // }

    // function creatorTakeOrLeaveResponse(
    //     bool _accept
    // ) public onlyCreator unresolved pastFirstFirmOffers {
    //     require(receiverTakeOrLeaveRequestGiven == true);

    //     if (_accept == true) {
    //         require(
    //             balance[creator] >= finalTakeOrLeaveRequestAmount,
    //             "you dont have enough funds to process this offer"
    //         );
    //         balance[creator] -= finalTakeOrLeaveRequestAmount;
    //         balance[opponent] += finalTakeOrLeaveRequestAmount;
    //         resolved = true;
    //         receiversTakeOrLeaveRespondedTo = true;
    //         emit TakeItOrLeaveItResponse(
    //             creator,
    //             true,
    //             finalTakeOrLeaveRequestAmount
    //         );
    //     } else if (_accept == false) {
    //         require(balance[opponent] >= penalty);
    //         balance[opponent] -= penalty;
    //         balance[summFoundation] += penalty;
    //         receiversTakeOrLeaveRespondedTo = true;
    //         emit TakeItOrLeaveItResponse(creator, false, 0);
    //     }
    // }
}
