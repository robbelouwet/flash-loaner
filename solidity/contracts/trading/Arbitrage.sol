pragma solidity ^0.6.6;

import './UniswapV2Library.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IERC20.sol';

/**
Leen een bepaalde token op Pancakeswap en verkoop op bakeryswap
vb: startArbitrage(WETH, DAI, 1M, 0) -> leent 1000000 WETH, en pancakeCall word uitgevoerd

pancakeCall(WETH_DAI_PAIR, 1M, 0) -> wordt aangeroepen
*/
contract Arbitrage {
  address owner;

  address public pancakeFactory;
  uint constant deadline = 10 days;
  IUniswapV2Router02 public bakeryRouter;

  constructor(address _pancakeFactory, address _bakeryRouter, address _owner) public {
    pancakeFactory = _pancakeFactory;  
    bakeryRouter = IUniswapV2Router02(_bakeryRouter);
    owner = _owner;
  }

  // Start de arbitrage, een call naar .swap met 0 als 1 van de hoeveelheden (en 'not empty') triggert
  // een flash loan ipv een vanilla trade
  function startArbitrage(
    address token0, // WETH
    address token1, // DAI
    uint amount0, // 1 000 000
    uint amount1 // 0 -----> ge swapt 0 met 1M, betekent dat ge leent
  ) external {
    address pairAddress = IUniswapV2Factory(pancakeFactory).getPair(token0, token1);
    require(pairAddress != address(0), 'This pool does not exist');
    IUniswapV2Pair(pairAddress).swap(
      amount0, 
      amount1, 
      address(this), 
      bytes('not empty')
    );
  }

  function withdraw() public isOwner {
    owner.transfer()
  }

  function pancakeCall(
    address _sender, 
    uint _amount0, 
    uint _amount1, 
    bytes calldata _data
  ) external {
    address[] memory path = new address[](2);
    uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();

    require(
      msg.sender == UniswapV2Library.pairFor(pancakeFactory, token0, token1), 
      'Unauthorized'
    ); 
    require(_amount0 == 0 || _amount1 == 0);

    path[0] = _amount0 == 0 ? token1 : token0;
    path[1] = _amount0 == 0 ? token0 : token1;

    IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
    
    token.approve(address(bakeryRouter), amountToken);

    uint amountRequired = UniswapV2Library.getAmountsIn(
      pancakeFactory, 
      amountToken, 
      path
    )[0];
    uint amountReceived = bakeryRouter.swapExactTokensForTokens(
      amountToken, 
      amountRequired, 
      path, 
      msg.sender, 
      deadline
    )[1];

    IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
    otherToken.transfer(msg.sender, amountRequired);
    otherToken.transfer(tx.origin, amountReceived - amountRequired);
  }
}
