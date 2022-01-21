// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract new2 is VRFConsumerBase{
    bytes32 internal keyHash;
    uint internal fee;
    uint[] public randomNumber;
    address public organiser;
    address payable[] players;
    uint public lotteryid;
    mapping (address => uint[]) public lotteryNumbers;
    mapping (uint => address payable[]) public lotteryHistory;

    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, //VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 //link token address
        )
        {
            keyHash= 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee= 0.1 * 10**18;
            organiser= msg.sender;
            lotteryid=1;
        }
        
    

    function Get_Random_Number() public returns (bytes32 requestid) {
        require (LINK.balanceOf(address(this))>=fee, "Not enough link");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestid, uint randomness) internal override {
        randomNumber.push((randomness%59)+1);
        if(randomNumber.length==6) {
            payWinner();
        }
        
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

    function lottery_entrance(uint[] memory ticketNumbers) public payable {
        require (msg.value==1 ether, "insufficient funds");
        players.push(payable(msg.sender));
        lotteryNumbers[msg.sender]=ticketNumbers;
    }

    function winner() public OnlyOrganiser {
        for(uint i=0; i<6; i++){
            Get_Random_Number();
        }  
    }

    function payWinner() internal {

        uint prize_for_each_crct_number = (address(this).balance)/6;

        payable(organiser).transfer((40*(address(this).balance))/100);

        for(uint i=0; i<6; i++) {
            for(uint j=0; j<players.length; j++) {
                if(randomNumber[i]==lotteryNumbers[players[j]][i]) {
                    players[j].transfer(prize_for_each_crct_number);
                    lotteryHistory[lotteryid].push(players[j]);
                    break;
                }
                if(j==5)
                {
                    lotteryHistory[lotteryid].push(payable(address(0)));
                }
            }
        }

        payable(organiser).transfer(address(this).balance);
        lotteryid++;
        players= new address payable[](0);

    }

    modifier OnlyOrganiser() {
        require(msg.sender==organiser);
        _;
    }
}