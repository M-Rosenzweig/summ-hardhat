// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SoftOffers.sol"; 


contract FirmOffers is SoftOffers {

    event FirmOfferGiven(address _who, uint _number, bool _bothGivenAndProcessed);
    event FirmOfferStatus(bool _withinRange, uint _giverOffer, uint _receiverOffer, uint _percentageDiff, uint amountDiff, uint _compromiseAmount, uint _finalFirmAmount, bool _resolved, bool _penalties);
    event PenaltyGiven(address _whoPaid, address _whoReceived, uint _penaltyAmount); 
    event AmountDistanceTie(bool _tie); 
    event TakeItOrLeaveItOfferGiven(address _who, bool _given, uint _amount); 
    event TakeItOrLeaveItResponse(address _whoResponded, bool _accepted, uint _amount); 

    FirmReceiverOffer[] private firmReceiverOffers;
    FirmGiverOffer[] private firmGiverOffers;

  constructor(address _termsAddress)
  SoftOffers(_termsAddress){
  }


 function initiateFirmGiverOffer(uint _amount) public onlyCreator unresolved{
     require(currentFirmGiverOffer < totalFirmOffersCap); 
     uint bufferAmount = _amount * firmRange / 200; 
     uint totalRequiredAmount = _amount + bufferAmount; 
     require(balance[msg.sender] >= totalRequiredAmount);
     require(mediumNumber > 0); 
     currentFirmGiverOffer++; 
    require(currentFirmGiverOffer == currentFirmReceiverOffer || (currentFirmGiverOffer - 1) == currentFirmReceiverOffer, "you must wait until the opponent puts in their offer to initate an additonal offer"); 

     FirmGiverOffer memory newOffer = FirmGiverOffer({
       amount: _amount, 
       number: currentFirmGiverOffer, 
       given: true
     }); 
     firmGiverOffers.push(newOffer); 

     if(currentFirmGiverOffer == currentFirmReceiverOffer && firmReceiverOffers[currentFirmReceiverOffer -1].given == true){
       processFirmOffer(totalRequiredAmount); 
       emit FirmOfferGiven(creator, currentFirmGiverOffer, true); 
     } else {
       emit FirmOfferGiven(creator, currentFirmGiverOffer, false); 
     }
   }

  function initiateFirmReceiverOffer(uint _amount) public onlyOpponent unresolved {
    require(currentFirmReceiverOffer <= totalFirmOffersCap); 
    require(balance[msg.sender] >= penalty);
    require(mediumNumber > 0); 
    require(currentFirmReceiverOffer <= totalFirmOffersCap);
    currentFirmReceiverOffer++; 
    require(currentFirmReceiverOffer == currentFirmGiverOffer || (currentFirmReceiverOffer - 1) == currentFirmGiverOffer, "you must wait until the opponent puts in their offer to initate an additonal offer"); 

    FirmReceiverOffer memory newOffer = FirmReceiverOffer({
      amount: _amount, 
      number: currentFirmReceiverOffer, 
      given: true
    }); 

    firmReceiverOffers.push(newOffer); 

    if(currentFirmReceiverOffer == currentFirmGiverOffer && firmReceiverOffers[currentFirmGiverOffer -1].given == true){
      processFirmOffer(penalty); 
      emit FirmOfferGiven(opponent, currentFirmReceiverOffer, true); 
    } else {
      emit FirmOfferGiven(opponent, currentFirmReceiverOffer, false); 
    }
  }

  function processFirmOffer(uint _amount) private {
    require(balance[opponent] >= penalty);
    require(balance[creator] >= _amount);
    uint giverOffer = (firmGiverOffers[currentFirmGiverOffer -1].amount); 
    uint receiverOffer = (firmReceiverOffers[currentFirmReceiverOffer -1].amount); 
    uint percentageDiff = receiverOffer > giverOffer ? ((receiverOffer - giverOffer) * 100 / receiverOffer) : ((giverOffer - receiverOffer) * 100 / giverOffer); 
    uint amountDiff = receiverOffer > giverOffer ? receiverOffer - giverOffer : giverOffer - receiverOffer; 
    uint compromiseAmount = (amountDiff / 2); 

    if(percentageDiff <= firmRange && receiverOffer > giverOffer ) {
       finalFirmOffer = giverOffer + compromiseAmount; 
       balance[creator] -= finalFirmOffer;
       balance[opponent] += finalFirmOffer;  
       // transfer nft receipts
       resolved = true; 
       emit FirmOfferStatus(true, giverOffer, receiverOffer, percentageDiff, amountDiff, compromiseAmount, finalFirmOffer, resolved, false); 
     } else if(percentageDiff <= firmRange && giverOffer > receiverOffer){
       finalFirmOffer = receiverOffer + compromiseAmount; 
       balance[creator] -= finalFirmOffer; 
       balance[opponent] += finalFirmOffer; 
       // transfer nft receipts
       resolved = true; 
       emit FirmOfferStatus(true, giverOffer, receiverOffer, percentageDiff, amountDiff, compromiseAmount, finalFirmOffer, resolved, false); 
     } else if(percentageDiff > firmRange) {
       processFirmPenalties(); 
       emit FirmOfferStatus(false, 0, 0, 0, 0, 0, 0, resolved, true); 
     }
  }

     function processFirmPenalties() private {
      uint giverOffer = (firmGiverOffers[currentFirmGiverOffer -1].amount); 
      uint receiverOffer = (firmReceiverOffers[currentFirmReceiverOffer -1].amount); 
      uint giverDiff = giverOffer > mediumNumber ? giverOffer - mediumNumber : mediumNumber - giverOffer; 
      uint receiverDiff = receiverOffer > mediumNumber ? receiverOffer - mediumNumber : mediumNumber - receiverOffer; 

      if(giverDiff > receiverDiff){
        balance[creator] -= penalty; 
        balance[opponent] += penalty; 
        emit PenaltyGiven(creator, opponent, penalty); 
      } else if(receiverDiff > giverDiff){
        balance[opponent] -= penalty;
        balance[creator] += penalty;  
        emit PenaltyGiven(opponent, creator, penalty);  
      } else if(giverDiff == receiverDiff){
        emit AmountDistanceTie(true); 
      }
     }

    // function creatorTakeItOrLeaveIt(uint _amount) public onlyCreator unresolved pastFirstFirmOffers{
    //   require(creatorTakeItOrLeaveItGiven == false); 
    //   require(balance[creator] >= _amount); 
    //   finalTakeItOrLeaveItAmount = _amount; 
    //   creatorTakeItOrLeaveItGiven = true; 
    //   emit TakeItOrLeaveItOfferGiven(creator, true, _amount); 
    // }

    // function receiverTakeItOrLeaveItResponse(bool _accept) public onlyOpponent unresolved pastFirstFirmOffers{
    //   require(creatorTakeItOrLeaveItGiven == true); 

    //   if(_accept == true){
    //   require(balance[creator] >= finalTakeItOrLeaveItAmount);
    //   balance[creator] -= finalTakeItOrLeaveItAmount; 
    //   balance[opponent] += finalTakeItOrLeaveItAmount;
    //   // transfer nft receipt 
    //   resolved = true; 
    //   creatorTakeItOrLeaveItRespondedTo = true; 
    //   emit TakeItOrLeaveItResponse( opponent, true, finalTakeItOrLeaveItAmount);  
    //   } 
      
    //   else if(_accept == false){
    //     require(balance[creator] >= penalty); 
    //     balance[creator] -= penalty; 
    //     balance[summFoundation] += penalty;  
    //     creatorTakeItOrLeaveItRespondedTo = true; 
    //     emit TakeItOrLeaveItResponse(opponent, false, 0); 
    //   } 
    // }

    // function receiverTakeOrLeave(uint _amount) public onlyOpponent unresolved pastFirstFirmOffers{
    //   require(receiverTakeOrLeaveRequestGiven == false); 
    //   require(balance[creator] >= penalty); 
    //   finalTakeOrLeaveRequestAmount = _amount; 
    //   receiverTakeOrLeaveRequestGiven = true; 
    //   emit TakeItOrLeaveItOfferGiven(opponent, true, _amount); 
    // }

    // function creatorTakeOrLeaveResponse(bool _accept) public onlyCreator unresolved pastFirstFirmOffers{
    //   require(receiverTakeOrLeaveRequestGiven == true); 

    //   if(_accept == true) {
    //     require(balance[creator] >= finalTakeOrLeaveRequestAmount);
    //     balance[creator] -= finalTakeOrLeaveRequestAmount; 
    //     balance[opponent] += finalTakeOrLeaveRequestAmount; 
    //     resolved = true; 
    //     receiversTakeOrLeaveRespondedTo = true; 
    //     emit TakeItOrLeaveItResponse(creator, true, finalTakeOrLeaveRequestAmount); 
    //   }
    //   else if(_accept == false){
    //     require(balance[opponent] >= penalty); 
    //     balance[opponent] -= penalty; 
    //     balance[summFoundation] += penalty; 
    //     receiversTakeOrLeaveRespondedTo = true; 
    //     emit TakeItOrLeaveItResponse(creator, false, 0); 
    //   }
    // }
}


 