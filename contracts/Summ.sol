// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SummTerms.sol"; 
import "hardhat/console.sol";

error Summ__OnlyCreator(address _creator); 
error Summ__OnlyOpponent(address _opponent); 
error Summ__NotEnoughBalance(); 
// error Summ__NotEnoughBalanceToCoverPenalty(uint _balancePlusPenaltyAmount); 

contract Summ{

     event DepositGiven(uint _amount); 

     SummTerms internal summTerms; 

     address payable public creator; 
     address payable public opponent;
     address payable internal summFoundation;  

     mapping (address => uint) internal balance; 

     uint public totalSoftOffersCap; 
     uint public totalFirmOffersCap;
     uint public softRange;  
     uint public firmRange; 
     uint public penaltyPercent;  

     bool public firstRoundSafe; 

     uint public culumativeGiverAmount; 
     uint public culumativeReceiverAmount; 

     uint public mediumNumber; 
     uint public penalty;

     bool public resolved; // maybe change these two states to an Enum (resolved and softRoundActive) // pastFirstFirmOffers and softRoundCurrentlyActive modifiers... 
     bool public softRoundActive = true;  

    //  uint public currentSoftGiverOffer; 
    //  uint public currentSoftReceiverOffer;

     uint public currentFirmGiverOffer; 
     uint public currentFirmReceiverOffer; 

     uint internal finalSoftOffer; 
     uint internal finalFirmOffer;  

     bool internal creatorTakeItOrLeaveItGiven; 
    //  uint public finalTakeItOrLeaveItAmount; 
     bool internal creatorTakeItOrLeaveItRespondedTo; 

     bool internal receiverTakeOrLeaveRequestGiven; 
     uint public finalTakeOrLeaveRequestAmount; 
     bool internal receiversTakeOrLeaveRespondedTo; 

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
       if(msg.sender != creator) {
         revert Summ__OnlyCreator(creator); 
       }
    // require(msg.sender == creator);
    _;
  }

    modifier onlyOpponent() {
      if(msg.sender != opponent){
        revert Summ__OnlyOpponent(opponent); 
      }
    // require(msg.sender == opponent);
    _;
  }


    modifier unresolved() {
      require(resolved == false); 
      _; 
    }

    // -----



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

     function getSummary() public view returns(uint, uint, address, address, uint, uint, uint, bool) {
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
       emit DepositGiven(msg.value);  
     }

     function checkBalance() public view returns(uint) {
       return balance[msg.sender]; 
     }

     function fullWithdrawl() public {
      //  if( msg.sender == creator && creatorTakeItOrLeaveItGiven == true && creatorTakeItOrLeaveItRespondedTo == false){
      //    uint availableWithdrawAmount = (balance[creator] - penalty); 
        //  require(availableWithdrawAmount > penalty);
      //    balance[creator] -= (availableWithdrawAmount + penalty); 
      //    balance[summFoundation] += penalty;
      //    creator.transfer(availableWithdrawAmount);
      //    creatorTakeItOrLeaveItRespondedTo = true;  
      //  } else if(msg.sender == opponent && receiverTakeOrLeaveRequestGiven == true && receiversTakeOrLeaveRespondedTo == false){
      //    uint availableWithdrawAmount = (balance[opponent] - penalty); 
      //    balance[opponent] -= (availableWithdrawAmount + penalty);
      //    balance[summFoundation] += penalty;  
      //    opponent.transfer(availableWithdrawAmount); 
      //    receiversTakeOrLeaveRespondedTo = true; 
      //  }
      //  else{
         uint amountToWithdraw = balance[msg.sender]; 
         balance[msg.sender] -= amountToWithdraw; 
         payable(msg.sender).transfer(amountToWithdraw); 
      //  }
     }

    function partialWithdraw(uint _amount) public {
      // if( msg.sender == creator && creatorTakeItOrLeaveItGiven == true && creatorTakeItOrLeaveItRespondedTo == false){
      // require(balance[creator] >= (_amount + penalty));
      // balance[creator] -= (_amount + penalty); 
      // balance[summFoundation] += penalty;
      // creator.transfer(_amount);
      // creatorTakeItOrLeaveItRespondedTo = true; 
      // } else if(msg.sender == opponent && receiverTakeOrLeaveRequestGiven == true && receiversTakeOrLeaveRespondedTo == false) {
      //   require(balance[opponent] >= (_amount + penalty)); 
      //   if(balance[opponent] < (_amount + penalty)){
      //     revert Summ__NotEnoughBalanceToCoverPenalty(_amount + penalty); 
      //   }
      //   balance[opponent] -= (_amount + penalty);
      //   balance[summFoundation] += penalty; 
      //   opponent.transfer(_amount); 
      //   receiversTakeOrLeaveRespondedTo = true;  
      // }
      //  else {
      require(_amount <= balance[msg.sender]); 
      if(_amount > balance[msg.sender]){
        revert Summ__NotEnoughBalance(); 
      }
      balance[msg.sender] -= _amount; 
      payable(msg.sender).transfer(_amount);
      // } 
    } 

}