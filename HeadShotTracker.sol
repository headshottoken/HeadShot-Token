// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotLib.sol";

contract HeadShotTracker is ERC20, Ownable {
    uint256 private _totalSupply;

    struct TrxInfo {
        uint256 mode;
        address buyer;
        uint256 date;
        uint256 count;
    }

    uint256 private _price;
    uint256 private _code;
    uint256 private _category;
    string private _desc;
    string private _title;

    mapping (address => uint256) private _balances;

    mapping(uint256 => mapping(address => TrxInfo)) private _trxMap;
    TrxInfo[] private _trxList;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    receive() external payable {}

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        _setBalance(account, newBalance);
    }

    function increaseBalance(address payable account, uint256 addBalance) internal {
        uint256 currBalance = _balances[account];
        uint256 newBalance = currBalance + addBalance;
        _setBalance(account, newBalance);
        _totalSupply += addBalance;
    }

    function decreaseBalance(address payable account, uint256 subBalance) internal {
        uint256 currBalance = _balances[account];
        uint256 newBalance = currBalance - subBalance;
        require(newBalance >= 0, "ERR");
        _setBalance(account, newBalance);
        _totalSupply -= subBalance;
    }

    function buy(address account, uint256 addBalance) external onlyOwner returns (bool) {
        increaseBalance(payable(account), addBalance);
        TrxInfo memory trxInfo = TrxInfo(1, account, block.timestamp, addBalance);
        _trxMap[1][account] = trxInfo;
        _trxList.push(trxInfo);
        return true;
    }

    function sell(address account, uint256 subBalance) external onlyOwner returns (bool) {
        decreaseBalance(payable(account), subBalance);
        TrxInfo memory trxInfo = TrxInfo(1, account, block.timestamp, subBalance);
        _trxMap[2][account] = trxInfo;
        _trxList.push(trxInfo);
        return true;
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];
        if(newBalance > currentBalance) {
            uint256 addAmount = newBalance - currentBalance;
            _mint(address(this), addAmount);
            _transfer(address(this), account, addAmount);
        } else if(newBalance < currentBalance) {
            uint256 subAmount = currentBalance - newBalance;
            _transfer(account, address(this), subAmount);
            _burn(address(this), subAmount);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("HeadShotTracker: method not implemented");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("HeadShotTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("HeadShotTracker: method not implemented");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("HeadShotTracker: method not implemented");
    }

    function setTitle(string memory title_) external onlyOwner {
        _title = title_;
    }

    function setDescription(string memory description_) external onlyOwner {
        _desc = description_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        _price = price_;
    }

    function setCategory(uint256 category_) external onlyOwner {
        _category = category_;
    }

    function setCode(uint256 code_) external onlyOwner {
        _code = code_;
    }

    function title() public view returns (string memory) {
        return _title;
    }

    function description() public view returns (string memory) {
        return _desc;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function category() public view returns (uint256) {
        return _category;
    }

    function listTrx(uint limit_, uint page_) external view onlyOwner returns (
        uint256[] memory,
        address[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        uint listCount = _trxList.length;

        uint rowStart = 0;
        uint rowEnd = 0;
        uint rowCount = listCount;
        bool pagination = false;

        if (limit_ > 0 && page_ > 0){
            rowStart = (page_ - 1) * limit_;
            rowEnd = (rowStart + limit_) - 1;
            pagination = true;
            rowCount = limit_;
        }

        uint256[] memory _modes = new uint256[](rowCount);
        address[] memory _buyers = new address[](rowCount);
        uint256[] memory _dates = new uint256[](rowCount);
        uint256[] memory _counts = new uint256[](rowCount);

        uint id = 0;
        uint j = 0;

        if (listCount > 0){
            for (uint i = 0; i < listCount; i++) {
                bool insert = !pagination;
                if (pagination){
                    if (j >= rowStart && j <= rowEnd){
                        insert = true;
                    }
                }
                if (insert){
                    //if (mode_ == _trxList[i].mode){
                    _modes[id] = _trxList[i].mode;
                    _buyers[id] = _trxList[i].buyer;
                    _dates[id] = _trxList[i].date;
                    _counts[id] = _trxList[i].count;
                    id++;
                    //}
                }
                j++;
            }
        }

        return (_modes, _buyers, _dates, _counts);
    }
}
