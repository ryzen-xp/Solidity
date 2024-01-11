//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
contract ticket{
    address public manger;
    uint public Price;
    
    constructor(uint amount) {
        manger = msg.sender;
        Price = amount;
    }
    
     mapping(address=>mapping(string=>bool))public booking;
    // mapping (address=>string) bookings;
  function Book_ticket(string memory _name ) public payable   {
       require(msg.value >=  Price );
        booking[msg.sender][_name] = true; 


  }
  function Entry(string memory _name)public  view returns(string memory){
   if(booking[msg.sender][_name]!= true){
   return "BSDK Nikal Laude pahli furst me";
   }
   
   else{
    // require(booking[msg.sender][_name]== true);
      
      return "welcome Mother fucker!!!";
   }

  }

    
}