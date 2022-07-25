// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract RefProxy{

//// This contract is a graph, input X to get Y

    function getValue(uint X) public pure returns (uint){

        if(X <= 500){

            return (X*5)/100;
        }
        
        if(X <= 1000){

            return (X*7)/100;
        }

        if(X <= 2500){

            return (X*9)/100;
        }

        if(X <= 5000){

            return (X*12)/100;
        }

        if(X <= 10000){

            return (X*20)/100;
        }

        if(X <= 20000){

            return (X*30)/100;
        }

        if(X <= 50000){

            return (X*40)/100;
        }

        if(X <= 100000){

            return (X*50)/100;
        }

        return 0;
    }
}
