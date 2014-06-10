//+------------------------------------------------------------------+
//|                                     bai_triangle_breakout_V1.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//  Version 1.0
//      For this version, we plan to implement basic triangle pattern.
//      Only for period 5 mins.
//  Future Features
//  Version 1.1
//      import average range for SL/TP
//  Version 1.2
//      Add fake breakout(imagine a reverse fake break,and...)
//  Version 2.0
//      Add grid trading
//  Version 3.0
//      Maybe add hedge for BIG/Solid profit
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
//------------------------------
// INPUT
//------------------------------
extern double    Lots = 0.1;
//------------------------------
// Global
//------------------------------
double AvgRange_5B;
double AvgRange_10B;
double retrace_low, break_up;
double retrace_high, break_down;
bool wait_buy = False;
bool wait_sell = False;
int MagicNum = 5522250;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    CalcuteAvgRange();
    Comment("bai_trangle_breakout_V1 EA\n",
            "Average Range in 5 5MIN_Bars:", AvgRange_5B, "\n",
            "Average Range in 10 5MIN_Bars:", AvgRange_10B, "\n");

    ReadyForMakeMoney();                                            //Entry Market anytime
    if(Volume[0]>1) return;
    if(wait_buy || wait_sell)   return;                              //Only ONE waiting trade
    DetectDoublePeak();                                             //Detect everyone new bars
  }
//+------------------------------------------------------------------+
void CalcuteAvgRange()
{
    int i;
    double sum = 0;
    for(i=1; i<6; i++)
    {
        sum += (High[i]-Low[i]);
    }
    AvgRange_5B = sum/5;
    sum = 0;
    for(i=1; i<11; i++)
    {
        sum += (High[i] - Low[i]);
    }
    AvgRange_5B = sum/10;
}

//+------------------------------------------------------------------+
//| Triangle breakout pattern                                        |
//                 E                                                 |
//    P      P    -                                                  |
//     -    - -  -                                                   |
//      -  -   L2                                                    |
//       L1                                                          |
// First, "L" is higher low. It's retracement. At the sametime it's  |
// one side of triangle.                                             |
// And the another side of the triangle is up resistant.             |
// "E" is the entry point. "P" is so called "POINT TO POINT".        |
//+------------------------------------------------------------------+
void DetectDoublePeak()
{
    int i;
    double high_last = High[1];
    double low_last = Low[1];
    
    for(i=2; i<50; i++)
    {
        if(high_last < High[i]){break;}
        if(high_last == High[i])
        {
            if(i<5){continue;}                                              // too close to ooxx
            retrace_low = iLowest(Symbol(), 0, MODE_LOW, i, 1);             // first retracement
            break_up = High[i];
            wait_buy = True;
            return;
        }
    }

    //TODO performence
    for(i=2; i<50; i++)
    {
        if(low_last > Low[i])   break;
        if(low_last == Low[i])
        {
            if(i<5) continue;
            retrace_high = iHighest(Symbol(), 0, MODE_HIGH, i, 1);
            break_down = Low[i];
            wait_sell = True;
            return;
        }
    }
}

void ReadyForMakeMoney()
{
    double sl, tp;
    int i,ret;
    if(wait_buy)
    {
        for(i=1; i<50; i++)
        {
            if(break_up==High[i])
            {
                break;
            }
        }
        //TODO maybe waste some odd chances
        if(i==1 || i==50)                               //There should be one more times retracement
        {
            wait_buy = False;
            return;
        }
        if(Ask - break_up > 20*Point && iLowest(Symbol(), 0, MODE_LOW, i, 0)>retrace_low)
        {
            sl = break_up - retrace_low;
            tp = 4*sl;
            ret = OrderSend(Symbol(), OP_BUY, Lots, Ask, 1, Bid-sl, Bid+tp, "comment", MagicNum, 0, Green);
            wait_buy = False;
            break_up = 0;
            retrace_low = 0;
            return;
        }
    }
    //
    if(wait_sell)
    {
        for(i=1; i<50; i++)
        {
            if(break_down==Low[i])
            {
                break;
            }
        }
        //TODO maybe waste some odd chances
        if(i==1 || i==50)                               //There should be one more times retracement
        {
            wait_sell = False;
            return;
        }
        if(break_down-Bid>20*Point && iHighest(Symbol(), 0, MODE_HIGH, i, 0)<retrace_high)
        {
            sl = retrace_high - break_down;
            tp = 4*sl;
            ret = OrderSend(Symbol(), OP_SELL, Lots, Bid, 1, Ask+sl, Ask-tp, "comment", MagicNum, 0, Red);
            wait_sell = False;
            retrace_high = 0;
            break_down = 0;
            return;
        }
    }
}

