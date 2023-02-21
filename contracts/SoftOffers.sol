// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "./SummTerms.sol"; 
import "./Summ.sol"; 
import "hardhat/console.sol";



contract SoftOffers is Summ {

  event SoftOfferGiven(address _who, uint _number, bool _bothGivenAndProcessed); 
  event InRange(bool _readyToAccept, bool _softRoundActive); 
  event OfferAccepted(address _who, bool _bothPartiesAccept, uint _finalCompromisedAmount, bool _resolved); 
  event OfferDeclined(address _who, bool _softOfferRoundsActive);
  event MediumNumberAndPenaltyVariablesSet(bool _set); 

  uint public numberVibessss = 613; 

  uint private currentSoftGiverOffer; 
  uint private currentSoftReceiverOffer;

  SoftReceiverOffer[] private softReceiverOffers; 
  SoftGiverOffer[] private softGiverOffers;

  modifier sameOfferNumberAndBothGivenUnresolved() {
      require(currentSoftGiverOffer == currentSoftReceiverOffer); 
      require(softReceiverOffers[currentSoftReceiverOffer -1].given == true && softGiverOffers[currentSoftGiverOffer -1].given == true);
      require(resolved == false); 
  _;
  }


  constructor(address _termsAddress) 
      Summ(_termsAddress){ 
  }


    function initiateSoftGiverOffer(uint _amount) public onlyCreator softRoundCurrentlyActive {
      uint bufferAmount = _amount * softRange / 200; 
      require(currentSoftGiverOffer < totalSoftOffersCap);  
      require(balance[creator] >= _amount + bufferAmount);
      require(_amount > 0);
      currentSoftGiverOffer++; 
      require(currentSoftGiverOffer == currentSoftReceiverOffer || (currentSoftGiverOffer - 1) == currentSoftReceiverOffer); 

      SoftGiverOffer memory newOffer = SoftGiverOffer({
        amount: _amount, 
        number: currentSoftGiverOffer, 
        given: true, 
        accepted: false
      }); 

      if(totalSoftOffersCap > 1 && currentSoftGiverOffer == 1){
        softGiverOffers.push(newOffer); 
        firstRoundSafe = true; 
      } else{
        culumativeGiverAmount += _amount; 
        softGiverOffers.push(newOffer); 
      }

    if (currentSoftGiverOffer == totalSoftOffersCap && currentSoftReceiverOffer == totalSoftOffersCap) {
    determineMediumNumberAndPenalty(culumativeGiverAmount, culumativeReceiverAmount);
    emit MediumNumberAndPenaltyVariablesSet(true); 
    }
    
    if (currentSoftGiverOffer == currentSoftReceiverOffer && softReceiverOffers[currentSoftReceiverOffer - 1].given == true) {
    processSoftOffer();
    emit SoftOfferGiven(creator,currentSoftGiverOffer, true); 
    } else {
    // console.log("waiting on the opponent to make an offer");
    emit SoftOfferGiven(creator,currentSoftGiverOffer, false); 
    } 
   }


     function initiateSoftReceiverOffer(uint _amount) public onlyOpponent softRoundCurrentlyActive {
      require(_amount > 0); 
      require(currentSoftReceiverOffer < totalSoftOffersCap);  
      currentSoftReceiverOffer++;
      require(currentSoftReceiverOffer == currentSoftGiverOffer || (currentSoftReceiverOffer - 1) == currentSoftGiverOffer); 

      SoftReceiverOffer memory newOffer = SoftReceiverOffer({
        amount: _amount, 
        number: currentSoftReceiverOffer, 
        given: true, 
        accepted: false
      });

      if(totalSoftOffersCap > 1 && currentSoftReceiverOffer == 1){
        softReceiverOffers.push(newOffer); 
        firstRoundSafe = true; 
      } else{
        culumativeReceiverAmount += _amount; 
        softReceiverOffers.push(newOffer);
      } 

      if (currentSoftGiverOffer == totalSoftOffersCap && currentSoftReceiverOffer == totalSoftOffersCap) {
      determineMediumNumberAndPenalty(culumativeGiverAmount, culumativeReceiverAmount);
      emit MediumNumberAndPenaltyVariablesSet(true); 
      }

     if(currentSoftGiverOffer == currentSoftReceiverOffer && softGiverOffers[currentSoftGiverOffer -1].given == true) {
       processSoftOffer(); 
       emit SoftOfferGiven(opponent,currentSoftReceiverOffer, true); 
     } else {
       emit SoftOfferGiven(opponent,currentSoftReceiverOffer, false);  
     }
    }

   function processSoftOffer() private {
     uint giverOffer = (softGiverOffers[currentSoftGiverOffer -1].amount); 
     uint receiverOffer = (softReceiverOffers[currentSoftReceiverOffer -1].amount);
     uint percentageDiff = receiverOffer > giverOffer ? ((receiverOffer - giverOffer) * 100 / receiverOffer) : ((giverOffer - receiverOffer) * 100 / giverOffer); 
     uint amountDiff = receiverOffer > giverOffer ? receiverOffer - giverOffer : giverOffer - receiverOffer; 
     uint compromiseAmount = (amountDiff / 2); 


     if(percentageDiff <= softRange && receiverOffer > giverOffer ) {
       finalSoftOffer = giverOffer + compromiseAmount;
       emit InRange(true, softRoundActive);  
     } else if(percentageDiff <= softRange && giverOffer > receiverOffer) {
       finalSoftOffer = receiverOffer + compromiseAmount; 
       emit InRange(true, softRoundActive);  
     } else if(currentSoftGiverOffer == totalSoftOffersCap && currentSoftReceiverOffer == totalSoftOffersCap) {
       softRoundActive = false;
       emit InRange(false, softRoundActive); 
      //  console.log("out of range. now moving to the firm rounds"); 
     } else {
       emit InRange(false, softRoundActive); 
     }
   }

   function creatorAcceptSoftOffer() public payable onlyCreator sameOfferNumberAndBothGivenUnresolved softRoundCurrentlyActive{
     if(softReceiverOffers[currentSoftReceiverOffer - 1].accepted == true) {
      require(balance[creator] >= finalSoftOffer); 
      softGiverOffers[currentSoftGiverOffer - 1].accepted = true; 
      // softGiverOffers[currentSoftGiverOffer - 1].complete = true; 

      balance[creator] -= finalSoftOffer;
      balance[opponent] += finalSoftOffer; 
      // transfer an NFT that says I have given X amount of funds for X debt or Item to Y address
      resolved = true; 
      emit OfferAccepted(creator,true, finalSoftOffer, resolved); 
     }
      else if(softReceiverOffers[currentSoftReceiverOffer - 1].accepted == false) {
      softGiverOffers[currentSoftGiverOffer - 1].accepted = true;
      emit OfferAccepted(creator,false, 0, resolved);  
      // console.log("waiting on opponent to accept for transfer to take place"); 
     } 
   }

   function opponentAcceptSoftOffer() public payable onlyOpponent sameOfferNumberAndBothGivenUnresolved softRoundCurrentlyActive { 
       if(softGiverOffers[currentSoftGiverOffer - 1].accepted == true) {
      
       require(balance[creator] >= finalSoftOffer); 
       softReceiverOffers[currentSoftReceiverOffer - 1].accepted = true;
      //  softReceiverOffers[currentSoftReceiverOffer - 1].complete = true; 

       balance[creator] -= finalSoftOffer;
       balance[opponent] += finalSoftOffer; 
       // transfer an nft that says I received payment for X debt or item from Y address. 
      resolved = true; 
      emit OfferAccepted(opponent,true, finalSoftOffer, resolved); 
     }
       else if(softGiverOffers[currentSoftGiverOffer - 1].accepted == false) {
       softReceiverOffers[currentSoftReceiverOffer -1].accepted = true; 
       emit OfferAccepted(opponent,false, 0, resolved);  
      //  console.log("waiting on creator to accept"); 
     } 
   }
   
   function declineSoftOffer() public sameOfferNumberAndBothGivenUnresolved {
    require(msg.sender == creator || msg.sender == opponent); 
    if(currentSoftGiverOffer == totalSoftOffersCap){
      softRoundActive = false; 
      emit OfferDeclined(msg.sender, softRoundActive);
      //  event OfferDeclined(address _who, bool _softOfferRoundsActive);
      // console.log("offer has been declined by the ${msg.sender} and we are moving to firm offers"); 
    } else{
      emit OfferDeclined(msg.sender, softRoundActive); 
      // msg.sender == creator ? console.log("creator declined and we can now both put in new offers") : console.log("opponent declined and we can now both put in new offers"); 
    }
   }

   
   function determineMediumNumberAndPenalty(uint _culumativeGiverAmount, uint _culumativeReceiverAmount) private {
    if(firstRoundSafe = true){
      mediumNumber = (_culumativeGiverAmount + _culumativeReceiverAmount) / ((currentSoftGiverOffer - 1) + (currentSoftReceiverOffer -1)); 
      penalty = (mediumNumber * penaltyPercent / 100); 
    } else{
      mediumNumber = (_culumativeGiverAmount + _culumativeReceiverAmount) / (currentSoftGiverOffer * 2);  
      penalty = (mediumNumber * penaltyPercent / 100); 
    }
   }

   function revealMediumNumberAndPenalty() public view returns(uint, uint){
     require(mediumNumber > 0 && softRoundActive == false); 
     return(mediumNumber, penalty); 
   }
   
}