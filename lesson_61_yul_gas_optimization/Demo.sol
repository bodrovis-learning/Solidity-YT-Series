// Простой пример на Yul:

contract YulDemo {
    function demo(uint a, uint b) external pure returns(uint) {
        uint result;

        assembly {
            switch b
            case 0 { result := 0 }
            case 1 { result := a }
            default
            {
                result := div(a, b)
            }
        }
        
        return result;
    }
}



// Откат транзакции на Solidity 2 способами
contract SolidityRevert {
    address owner;
    bool called;
    error NotAnOwner();

    constructor() {
        owner = msg.sender;
    }

    function callMe() external {
        //require(owner == msg.sender, "not an owner!");
        if(owner != msg.sender) {
            revert NotAnOwner();
        }
        
        called = true;
    }
}

// Откат на Yul
contract AssemblyRevert {
    address owner;
    bool called;

    constructor() {
        owner = msg.sender;
    }

    // 2266
    function callMe() external {
        assembly {
            if sub(caller(), sload(owner.slot)) {
                mstore(0x00, 0x20)
                mstore(0x20, 0x0d)
                mstore(0x40, 0x6e6f7420616e206f776e65722100000000000000000000000000000000000000)
                revert(0x00, 0x60)
            }
        }

        called = true;
    }
}



// Вызов другого контракта на Solidity
contract Target {
    uint public a;

    function callMe(uint256 _a) external {
        a = _a;
    }
}

contract Sol {
    function set(address _target, uint256 _a) external {
        Target(_target).callMe(_a);
    }
}

// Вызов на Yul
contract Assembly {
    function set(address _target, uint256 _a) external {
        assembly {
            mstore(0x00, hex"e73620c3")
            mstore(0x04, _a)

            if iszero(extcodesize(_target)) {
                revert(0x00, 0x00)
            }

            let success := call(gas(), _target, 0x00, 0x00, 0x24, 0x00, 0x00)
            
            if iszero(success) {
                revert(0x00, 0x00)
            }
        }
    }
}



// Проверка нулевого адреса Solidity
contract Sol {
    bool public called;

    function demo(address _target) public {
        require(_target != address(0), "zero address!");
        
        called = true;
    }

    function prep(string calldata _str) external pure returns(bytes memory enc, uint len) {
        enc = abi.encode(_str);
        len = bytes(_str).length;
    }
}


// Проверка нулевого адреса Yul
contract AddressZeroCheckAssembly {
    bool public called;

    function demo(address _target) public {
        assembly {
            if iszero(_target) {
                mstore(0x00, 0x20)
                mstore(0x20, 0x0d)
                mstore(0x40, 0x7a65726f20616464726573732100000000000000000000000000000000000000)
                revert(0x00, 0x60)
            }
        }

        called = true;
    }
}



// Проверка баланса контракта, Solidity и Yul
contract Demo {
    function getBalance() external view returns(uint ret) {
        // return address(this).balance; // 312
        assembly {
            ret := selfbalance() // 312
        }
    }
}



// Порождение события, Solidity
// contract Sol {
//     event Data(uint256 ts, uint256 bn, uint256 gsl);
//     // 2022
//     function callme() external {
//         emit Data(block.timestamp, block.number, block.gaslimit);
//     }
// }

// Порождение события, Yul
contract YulLog {
    event Data(uint256 ts, uint256 bn, uint256 gsl);

    function prep() external pure returns(bytes32) {
        return keccak256(bytes("Data(uint256,uint256,uint256)"));
    }


    function callme() external {
        assembly {
            mstore(0x00, timestamp())
            mstore(0x20, number())
            mstore(0x40, gaslimit())

            log1(
                0x00, 
                0x60,
                0xcd1ca2056c75ac58f38a59c81e508ddbfa5b305875a92d2e24364a1ac4355884
            )
        }
    }
}


// Хэширование, Solidity
contract ExpensiveHasher {
    bytes32 public hash;

    function hashIt(uint a, uint b, uint c) external {
        hash = keccak256(abi.encode(a, b, c));
    }
}

// Хэширование, Yul
contract CheapHasher {
    bytes32 public hash;

    function hashIt(uint, uint, uint) external {
        assembly {
            let freePtr := mload(0x40)
            
            calldatacopy(0x00, 0x04, 0x60)
            sstore(hash.slot, keccak256(0x00, 0x60))

            mstore(0x40, freePtr)
        }
    }
}


// Многократный вызов другого контракта, Solidity
contract Called {
    function add(uint256 a, uint256 b) external pure returns(uint) {
        return a + b;
    }
}

contract Solidity {
    function call(address _target) external pure returns(uint res) {
        Called called = Called(_target);

        uint res1 = called.add(1, 2);
        uint res2 = called.add(3, 4);

        res = res1 + res2;
    }
}

// Многократный вызов другого контракта, Yul
contract Assembly {
    function call(address _target) external view returns(uint res) {
        assembly {
            if iszero(extcodesize(_target)) {
                revert(0x00, 0x00)
            }

            // first call
            mstore(0x00, hex"771602f7")
            mstore(0x04, 0x01)
            mstore(0x24, 0x02)

            let success := staticcall(gas(), _target, 0x00, 0x44, 0x60, 0x20)

            if iszero(success) {
                revert(0x00, 0x00)
            }

            let res1 := mload(0x60)

            // second call
            mstore(0x04, 0x03)
            mstore(0x24, 0x4)

            success := staticcall(gas(), _target, 0x00, 0x44, 0x60, 0x20)

            if iszero(success) {
                revert(0x00, 0x00)
            }

            let res2 := mload(0x60)

            // add results
            res := add(res1, res2)

            // return data
            mstore(0x60, res)
            return(0x60, 0x20)
        }
    }
}




// Порождение контракта, Solidity
contract Called {
    function add(uint256 a, uint256 b) external pure returns(uint256) {
        return a + b;
    }
}

contract Solidity {
    function call() external returns (Called, Called) {
        Called called1 = new Called();
        Called called2 = new Called();
        return (called1, called2);
    }
}

// Порождение контракта, Yul
contract Assembly {
    function call() external returns(Called, Called) {
        bytes memory creationCode = type(Called).creationCode;

        assembly {
            let called1 := create(0x00, add(0x20, creationCode), mload(creationCode))
            let called2 := create(0x00, add(0x20, creationCode), mload(creationCode))

            // revert if either called1 or called2 returned address(0)
            if iszero(and(called1, called2)) {
                revert(0x00, 0x00)
            }

            mstore(0x00, called1)
            mstore(0x20, called2)

            return(0x00, 0x40)
        }
    }
}


// Поиск максимума, Solidity и Yul
contract Demo {
    function max(uint a, uint b) public pure returns (uint c) {
	    // c = a > b ? a : b; // 776

        assembly {
            c := xor(
                a, 
                mul(
                    xor(a, b),
                    gt(b, a)
                )
            )
        }
    }
}