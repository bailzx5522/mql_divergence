//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
//constant
#define ENTRY_WAIT_BUY  1
#define ENTRY_BUY       2
#define ENTRY_WAIT_SELL -1
#define ENTRY_SELL      -2
// INPUT values
extern  double TakeProfit    = 200;
extern  double StopLose    = 120;
extern  double Lots          = 0.1;
extern  double TrailingStop  = 10;
extern  bool ShowMarketInfo = false;
//
extern string separator1="*** MACD Settings ***";
extern int    fastEMA = 1;
extern int    slowEMA = 13;
extern int    signalSMA=1;
extern int    periodRSI = 5;
//calc average nge for 7 barsr
extern int    ar = 7;
//4pips
extern int    arv = 40;
//---- buffers
double macd[];
double signal[];
double AvgRange;
double ModeSpread;
int DivergenceDecision = 0;
int RSIDecision = 0;
int AverageRangeDecision = 0;
int lower_period = 0 ;
int MagicNum = 250250;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    GetLowerPeriod();
    GetMarketInfo();
    return(INIT_SUCCEEDED);
}

int GetMarketInfo()
{
/**
    ModeLow = MarketInfo(Symbol(), MODE_LOW);
    ModeHigh = MarketInfo(Symbol(), MODE_HIGH);
    ModeTime = MarketInfo(Symbol(), MODE_TIME);
    ModeBid = MarketInfo(Symbol(), MODE_BID);
    ModeAsk = MarketInfo(Symbol(), MODE_ASK);
    ModePoint = MarketInfo(Symbol(), MODE_POINT);
    ModeDigits = MarketInfo(Symbol(), MODE_DIGITS);
    ModeSpread = MarketInfo(Symbol(), MODE_SPREAD);
    ModeStopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    ModeLotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
    ModeTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    ModeTickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
    ModeSwapLong = MarketInfo(Symbol(), MODE_SWAPLONG);
    ModeSwapShort = MarketInfo(Symbol(), MODE_SWAPSHORT);
    ModeStarting = MarketInfo(Symbol(), MODE_STARTING);
    ModeExpiration = MarketInfo(Symbol(), MODE_EXPIRATION);
    ModeTradeAllowed = MarketInfo(Symbol(), MODE_TRADEALLOWED);
    ModeMinLot = MarketInfo(Symbol(), MODE_MINLOT);
    ModeLotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    // It is concluded information about the market
    if ( ShowMarketInfo == True )
    {
        Print("ModeLow:",ModeLow);
        Print("ModeHigh:",ModeHigh);
        Print("ModeTime:",ModeTime);
        Print("ModeBid:",ModeBid);
        Print("ModeAsk:",ModeAsk);
        Print("ModePoint:",ModePoint);
        Print("ModeDigits:",ModeDigits);
        Print("ModeSpread:",ModeSpread);
        Print("ModeStopLevel:",ModeStopLevel);
        Print("ModeLotSize:",ModeLotSize);
        Print("ModeTickValue:",ModeTickValue);
        Print("ModeTickSize:",ModeTickSize);
        Print("ModeSwapLong:",ModeSwapLong);
        Print("ModeSwapShort:",ModeSwapShort);
        Print("ModeStarting:",ModeStarting);
        Print("ModeExpiration:",ModeExpiration);
        Print("ModeTradeAllowed:",ModeTradeAllowed);
        Print("ModeMinLot:",ModeMinLot);
        Print("ModeLotStep:",ModeLotStep);
    }
**/
    ModeSpread = MarketInfo(Symbol(), MODE_SPREAD);
    return (0);
}

void GetLowerPeriod()
{
    switch(Period())
    {
        case 30:
            lower_period = 15;
            break;
        case 15:
            lower_period = 5;
            break;
        case 60:
            lower_period = 15;
            break;
        case 240:
            lower_period = 60;
            break;
        default:
            lower_period = 5;
    }
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
}
//+------------------------------------------------------------------+.
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //***************************Close or Modify Orders
    ReviewOrder();

    //***************************Make choice
    if(Volume[0]>1){return;}
    DivergenceDecision = 0;
    RSIDecision = 0;
    AverageRangeDecision = 0;
    CalculateDivergence();
    CalculateRSI();
    AverageRange();
    //***************************OpenOrder
    ComeonMoney();
}

//*******************************Review opened orders for SL or TP
void ReviewOrder()
{
    for(int i=0; i<OrdersTotal(); i++)
    {   
        KeyOfWin(i);
        //CheckRSIForClose(i);
    }
    return;
}

void KeyOfWin(int order)
{
    if(OrderSelect(order, SELECT_BY_POS, MODE_TRADES))
    {
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNum) return;
        int ticket = OrderTicket();
        bool ret;
        if(OrderType() == OP_BUY)
        {
            if(Bid-OrderOpenPrice()>3*AvgRange && OrderOpenPrice()-OrderStopLoss()>0)
            {
                Print(OrderOpenPrice(),"----------------------",OrderStopLoss());
                ret = OrderClose(ticket, 0.5*Lots, Bid, 1, Blue);
                ret = OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice()+ModeSpread, NormalizeDouble(Bid+200*Point, Digits), 0, Blue);
            }
        }
        if(OrderType() == OP_SELL)
        {
            if(OrderOpenPrice()-Ask>2*AvgRange && OrderOpenPrice()-OrderStopLoss()<0)
            {
                ret = OrderClose(ticket, 0.5*Lots, Ask, 1, Blue);
                ret = OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice()-ModeSpread, NormalizeDouble(Ask-200*Point,Digits), 0, Blue);
            }
        }
    }
}
//+------------------------------------------------------------------+.
//|Use RSI Divergence for close order                                |
//|Find a reverse according RSI divergence                           |
//+------------------------------------------------------------------+
void CheckRSIForClose(int order)
{
    if(iVolume(Symbol(), lower_period, 0)>1)   return;
    if(OrderSelect(order, SELECT_BY_POS, MODE_TRADES))
    {
        int bar = iBarShift(Symbol(), PERIOD_M5, OrderOpenTime());
        int high = bar;
        int low = bar;
        int ticket = OrderTicket();
        int ret;

        for(int i=bar-1; i>0; i--)
        {
            if(OrderType()==OP_BUY && iHigh(Symbol(), lower_period, i)>iHigh(Symbol(), lower_period, high))
            {
                if(iRSI(Symbol(), lower_period, periodRSI, PRICE_CLOSE, i)<iRSI(Symbol(), lower_period, periodRSI, PRICE_CLOSE, high))
                {
                    ret = OrderClose(ticket, OrderLots(), Bid, 1, clrBlue);
                    return;
                }
                high = i;
                continue;
            }
            if(OrderType()==OP_SELL && iLow(Symbol(), lower_period, i)<iLow(Symbol(), lower_period, low))
            {
                if(iRSI(Symbol(), lower_period, periodRSI, PRICE_CLOSE, i)>iRSI(Symbol(), lower_period, periodRSI, PRICE_CLOSE, low))
                {
                    ret = OrderClose(ticket, OrderLots(), Ask, 1, clrBlue);
                    return;
                }
                low = i;
                continue;
            }
        }
    }
}

//+------------------------------------------------------------------+.
//|Calculate RSI for open order.                                     |
//+------------------------------------------------------------------+
void CalculateRSI()
{
    double rsi = iRSI(Symbol(), 0, periodRSI, PRICE_CLOSE, 1);
    if(rsi<=50)
    {
        RSIDecision = ENTRY_BUY;
    }
    if(rsi>=50)
    {
        RSIDecision = ENTRY_SELL;
    }
}

void CalculateDivergence()
{
    int countedBars=IndicatorCounted();
    if(countedBars<0)   countedBars=0;
    int limit=Bars-countedBars;
    if(countedBars==0)  limit-=slowEMA;
    
    ArrayResize(macd, Bars);
    ArrayResize(signal, Bars);
    for(int i=limit; i>=0; i--)
    {
    
        CalculateMACD(i);
        CatchBullishDivergence(i+2);
        CatchBearishDivergence(i+2);
    }
}

void CalculateMACD(int i)
{
    macd[i]=iMACD(NULL,0,fastEMA,slowEMA,signalSMA,PRICE_CLOSE,MODE_MAIN,i);
    
    signal[i]=iMACD(NULL,0,fastEMA,slowEMA,signalSMA,PRICE_CLOSE,MODE_SIGNAL,i);
}

void CatchBullishDivergence(int shift)
{
   if(IsIndicatorTrough(shift)==false)
      return;
   int currentTrough=shift;
   int lastTrough=GetIndicatorLastTrough(shift);
   //*******************************regular bullish divergence
   if((lastTrough>=0 && lastTrough<Bars) && macd[currentTrough]>macd[lastTrough] && Low[currentTrough]<Low[lastTrough])
     {
        if(currentTrough == 2)
        {
            DivergenceDecision = ENTRY_BUY;
            
            return;
        }
     }
   //*******************************    hiden bearish devergence
   if((lastTrough>=0 && lastTrough<Bars) && macd[currentTrough]<macd[lastTrough] && Low[currentTrough]>Low[lastTrough])
     {
        if(currentTrough == 2)
        {
            //DivergenceDecision = ENTRY_BUY;
            return;
        }
     }
  }

void CatchBearishDivergence(int shift)
{
   if(IsIndicatorPeak(shift)==false)
      return;
   int currentPeak=shift;
   int lastPeak=GetIndicatorLastPeak(shift);
    //*********************************** regular bearish divergence
   if((lastPeak>=0 && lastPeak<Bars) && macd[currentPeak]<macd[lastPeak] && High[currentPeak]>High[lastPeak])
     {
        if(currentPeak == 2)
        {
            DivergenceDecision = ENTRY_SELL;
            return;
        }
     }
    // *********************************** hiden bearish divergence
    if((lastPeak>=0 && lastPeak<Bars) && macd[currentPeak]>macd[lastPeak] && High[currentPeak]<High[lastPeak])
    {
        if(currentPeak == 2)
        {
            //DivergenceDecision = ENTRY_SELL;
            return;
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsIndicatorPeak(int shift)
  {
   if(macd[shift]>=macd[shift+1] && macd[shift]>macd[shift+2] && 
      macd[shift]>macd[shift-1])
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsIndicatorTrough(int shift)
  {
   if(macd[shift]<=macd[shift+1] && macd[shift]<macd[shift+2] && 
      macd[shift]<macd[shift-1])
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetIndicatorLastPeak(int shift)
  {
   for(int i=shift+5;(i<Bars-3) && (i>1); i++)
     {
      if(signal[i] >= signal[i+1] && signal[i] >= signal[i+2] &&
         signal[i] >= signal[i-1] && signal[i] >= signal[i-2])
        {
         for(int j=i;(j<Bars-3) && (j>1); j++)
           {
            if(macd[j] >= macd[j+1] && macd[j] > macd[j+2] &&
               macd[j] >= macd[j-1] && macd[j] > macd[j-2])
               return(j);
           }
        }
     }
   return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetIndicatorLastTrough(int shift)
{
   for(int i=shift+5;(i<Bars-3) && (i>1); i++)
     {
      if(signal[i] <= signal[i+1] && signal[i] <= signal[i+2] &&
         signal[i] <= signal[i-1] && signal[i] <= signal[i-2])
        {
         for(int j=i;(j<Bars-3) && (j>1); j++)
           {
            if(macd[j] <= macd[j+1] && macd[j] < macd[j+2] &&
               macd[j] <= macd[j-1] && macd[j] < macd[j-2])
               return(j);
           }
        }
     }
   return(-1);
}
//+------------------------------------------------------------------+
//|    Get AverageRange and AverageRangeDecision                     |
//+------------------------------------------------------------------+
void AverageRange()
{
    double sum=0;
    for(int i=1; i<ar+1; i++)
    {
        sum = sum + MathAbs(High[i]-Low[i]);
    }
    AvgRange = sum/ar;
    if(AvgRange > arv*Point)
    {
        AverageRangeDecision = 1;
    }
}

void ComeonMoney()
{
    int ticket;
    if(DivergenceDecision==ENTRY_BUY && RSIDecision==ENTRY_BUY && AverageRangeDecision==1)
    {
        ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 1, Bid-StopLose*Point, Bid+TakeProfit*Point, "test_buy", MagicNum, 0, Green);
        if(ticket<0){    ProcessError(GetLastError());}
        DivergenceDecision = 0;
        RSIDecision = 0;
        AverageRangeDecision = 0;
        return;
    }
    if(DivergenceDecision==ENTRY_SELL && RSIDecision==ENTRY_SELL && AverageRangeDecision==1)
    {
        ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 1, Ask+StopLose*Point, Ask-TakeProfit*Point, "test_sell", MagicNum, 0, Green);
        if(ticket<0){    ProcessError(GetLastError());}
        DivergenceDecision = 0;
        RSIDecision = 0;
        AverageRangeDecision = 0;
        return;
    }
}

void ProcessError(int errno)
{
    switch(errno)
    {
        case 130:
            Print("ERROR NUMBER is ------------------------",errno);
            break;
        default:
            Print("ERROR NUMBER is ------------------------",errno);
            return;
    }
}