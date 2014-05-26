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
input double TakeProfit    = 200;
input double StopLose    = 120;
input double Lots          = 0.1;
input double TrailingStop  = 10;
//
extern string separator1="*** MACD Settings ***";
extern int    fastEMA = 1;
extern int    slowEMA = 13;
extern int    signalSMA=1;
extern int    periodRSI = 5;
//calc average nge for 7 barsr
extern int    ar = 7;
//5pips
extern int    arv = 50;
//---- buffers
double macd[];
double signal[];
int DivergenceDecision = 0;
int RSIDecision = 0;
int AverageRangeDecision = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    return(INIT_SUCCEEDED);
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
//---
    ReviewOrder();

    if(Volume[0]>1){return;}
    DivergenceDecision = 0;
    RSIDecision = 0;
    AverageRangeDecision = 0;
    CalculateDivergence();
    CalculateRSI();
    AverageRange();
    ComeonMoney();
}

//**************************Review opened orders for SL or TP
void ReviewOrder()
{
    if(iVolume(Symbol(), PERIOD_M5, 0)>1)   return;
    for(int i=0; i<OrdersTotal(); i++)
    {
        ModifySlTp(i);
        CheckRSIForClose(i);
    }
    return;
}

void ModifySlTp(int order)
{
    if(OrderSelect(order, SELECT_BY_POS, MODE_TRADES))
    {
        int ticket = OrderTicket();
        bool ret;
        if(OrderType() == OP_BUY)
        {
            if(OrderProfit()>100*Point && OrderStopLoss()<OrderOpenPrice())
            {
                ret = OrderClose(ticket, 0.5*Lots, Bid, 1, Blue);
                ret = OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice(), NormalizeDouble(Bid+200*Point, Digits), 0, Blue); 
            }
        }
        if(OrderType() == OP_SELL)
        {
            if(OrderProfit()>100*Point && OrderStopLoss()>OrderOpenPrice())
            {
                ret = OrderClose(ticket, 0.5*Lots, Ask, 1, Blue);
                ret = OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice(), NormalizeDouble(Ask-200*Point,Digits), 0, Blue);
            }
        }
    }
}

//**************************Use RSI Divergence for close order*********************//
void CheckRSIForClose(int order)
{
    if(OrderSelect(order, SELECT_BY_POS, MODE_TRADES))
    {
        int bar = iBarShift(Symbol(), PERIOD_M5, OrderOpenTime());
        int high = bar;
        int low = bar;
        int ticket = OrderTicket();
        int ret;
        int lower_period;
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
   //************************************regular bullish divergence
   if((lastTrough>=0 && lastTrough<Bars) && macd[currentTrough]>macd[lastTrough] && Low[currentTrough]<Low[lastTrough])
     {
        if(currentTrough == 2)
        {
            DivergenceDecision = ENTRY_BUY;
            
            return;
        }
     }
   // ******************************    hiden bearish devergence
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

void AverageRange()
{
    double sum=0;
    for(int i=1; i<ar+1; i++)
    {
        sum += (High[i]-Low[i]);
    }
    if(sum/ar > arv*Point)
    {
        AverageRangeDecision = 1;
    }
}

void ComeonMoney()
{
    int ticket = -1;
    if(DivergenceDecision==ENTRY_BUY && RSIDecision==ENTRY_BUY && AverageRangeDecision==1)
    {
        ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 1, Bid-StopLose*Point, Bid+TakeProfit*Point, "test_buy", 16384,0, Green);
        DivergenceDecision = 0;
        RSIDecision = 0;
        AverageRangeDecision = 0;
        return;
    }
    if(DivergenceDecision==ENTRY_SELL && RSIDecision==ENTRY_SELL && AverageRangeDecision==1)
    {
        ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 1, Ask+StopLose*Point, Ask-TakeProfit*Point, "test_sell", 16384, 0, Green);
        DivergenceDecision = 0;
        RSIDecision = 0;
        AverageRangeDecision = 0;
        return;
    }
}