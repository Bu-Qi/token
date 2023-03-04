// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;
library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

contract rbt_market  {

    address public USDT=0xDF0e293CC3c7bA051763FF6b026DA0853D446E38;
    address public RBT=0x09773FE7ccbE22298f416FD0f5d3f87D5adeE0e9;
    address payable public owner;
    address public DAO=0x25a783a377FA6eDf290886Ae87f0cb4251164037;
    uint256  public price=1000;

    uint256 public cursor=0;

    struct order {
        uint256 amount;
        uint256 buy_amount;
    }

    mapping (address => order) public order_book;

    address[] public order_list;


     constructor() {
        owner = payable(msg.sender);
    }

    function SELL (uint amount) public{
        require(!_isContract(msg.sender), "cannot be a contract");
        uint256 getUSDTamount=amount*price;
        TransferHelper.safeTransferFrom(RBT, msg.sender, DAO,amount);
        TransferHelper.safeTransferFrom(USDT, DAO,msg.sender,getUSDTamount);
    }
        // 是否合约地址
    function _isContract(address _addr) private view returns (bool ok) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }


    //排队
    function add_order() public{
        order storage user_order = order_book[msg.sender];
        require(user_order.amount == 0,"already exists order");
        //转u
        uint256 getUSDTamount=134000*price;
        TransferHelper.safeTransferFrom(USDT, msg.sender,address(this),getUSDTamount);
        user_order.amount = 134000;
        user_order.buy_amount = 0;
        order_book[msg.sender] = user_order;
        order_list.push(msg.sender);
    }

    //出售给队列
    function sell2order(uint amount) public{
        address order_address = order_list[cursor];//取当前排队位置
        order storage user_order = order_book[order_address];//取当前订单
        if(amount > (user_order.amount - user_order.buy_amount))
        {
            amount = user_order.amount - user_order.buy_amount;//如果当前订单剩余不足，就按剩余交易
        }
        
        uint256 getUSDTamount=amount*price;
        TransferHelper.safeTransferFrom(RBT, msg.sender, order_address,amount);
        TransferHelper.safeTransfer(USDT,msg.sender,getUSDTamount);

        //更新订单
        user_order.buy_amount += amount;
        order_book[msg.sender] = user_order;

        if(user_order.buy_amount == user_order.amount)
        {
            cursor++;//订单完成，更新游标
        }
    }

    function setOwner(address payable new_owner) public {
        require(msg.sender == owner);
        owner = new_owner;
    }

    function setDAO(address new_DAO) public {
        require(msg.sender == owner);
        DAO= new_DAO ;
    }
  
    function setprice(uint256 newprice) public {
        require(msg.sender == owner);
        price = newprice ;
    }
}
