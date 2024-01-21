// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract HeritageContract {
    uint256 heritageId;

    event Create(
        uint256 value,
        uint256 claimTime,
        uint256 createTime,
        address indexed sender,
        address indexed recipient,
        bool status
    );

    event Change(
        uint256 heritageId,
        uint256 value,
        uint256 claimTime,
        uint256 changeTime,
        address indexed recipient
    );

    event Claim(
        uint256 heritageId,
        uint256 claimTime,
        address indexed recipient,
        bool status
    );

    error ClaimTimeMustGreaterThanCurrentTime();
    error RecipientMustBeDifferentFromSender();
    error ValueMustGreaterThanZero();
    error TransactionFailed();
    error NotRecipient();
    error NotSender();
    error HeritageHasBeenClaimed();
    error ClaimTimeNotFulfilled();

    constructor() {
        heritageId = 1;
    }

    struct Heritage {
        uint256 value;
        uint256 claimTime;
        address sender;
        address recipient;
        bool status;
    }

    mapping(uint256 => Heritage) public heritages;

    receive() external payable {}

    fallback() external payable {}

    function createHeritage(
        uint256 _claimTime,
        address _recipient
    ) external payable {
        if (_claimTime <= block.timestamp) {
            revert ClaimTimeMustGreaterThanCurrentTime();
        }

        if (msg.value <= 0) {
            revert ValueMustGreaterThanZero();
        }

        if (_recipient == msg.sender) {
            revert RecipientMustBeDifferentFromSender();
        }

        (bool success, ) = address(this).call{value: msg.value}("");
        if (!success) {
            revert TransactionFailed();
        }

        heritages[heritageId] = Heritage({
            value: msg.value,
            claimTime: _claimTime,
            sender: msg.sender,
            recipient: _recipient,
            status: false
        });

        heritageId++;

        emit Create(
            msg.value,
            _claimTime,
            block.timestamp,
            msg.sender,
            _recipient,
            false
        );
    }

    function changeHeritage(
        uint256 _heritageId,
        uint256 _claimTime,
        address _recipient
    ) external payable {
        if (heritages[_heritageId].status) {
            revert HeritageHasBeenClaimed();
        }

        if (msg.sender != heritages[_heritageId].sender) {
            revert NotSender();
        }

        if (_claimTime <= block.timestamp) {
            revert ClaimTimeMustGreaterThanCurrentTime();
        }

        if (msg.value <= 0) {
            revert ValueMustGreaterThanZero();
        }

        if (_recipient == msg.sender) {
            revert RecipientMustBeDifferentFromSender();
        }

        uint256 values = heritages[_heritageId].value;

        (bool receiptSuccess, ) = msg.sender.call{value: values}("");
        if (!receiptSuccess) {
            revert TransactionFailed();
        }

        (bool sendingSuccess, ) = address(this).call{value: msg.value}("");
        if (!sendingSuccess) {
            revert TransactionFailed();
        }

        heritages[_heritageId].value = msg.value;
        heritages[_heritageId].claimTime = _claimTime;
        heritages[_heritageId].recipient = _recipient;

        emit Change(
            _heritageId,
            msg.value,
            _claimTime,
            block.timestamp,
            _recipient
        );
    }

    function claimHeritage(uint256 _heritageId) external {
        if (msg.sender != heritages[_heritageId].recipient) {
            revert NotRecipient();
        }

        if (block.timestamp < heritages[_heritageId].claimTime) {
            revert ClaimTimeNotFulfilled();
        }

        if (heritages[_heritageId].status) {
            revert HeritageHasBeenClaimed();
        }

        address recipient = heritages[_heritageId].recipient;
        uint256 values = heritages[_heritageId].value;

        (bool success, ) = recipient.call{value: values}("");
        if (!success) {
            revert TransactionFailed();
        }

        heritages[_heritageId].status = true;

        emit Claim(_heritageId, block.timestamp, msg.sender, true);
    }

    function getHeritageId() external view returns (uint256) {
        return heritageId;
    }
}
