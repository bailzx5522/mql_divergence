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
bool wait_buy = false;
bool wait_sell = false;
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
    //if(wait_buy || wait_sell)   return;                              //Only ONE waiting trade
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
        if(wait_buy)    break;
        if(High[i]-high_last>2*Point) break;
        //if(MathAbs(high_last-High[i])<=5*Point)         //TODO may use AverageRange
        if(high_last-High[i]<=5*Point && High[i]-high_last<=2*Point)             //TODO may use AverageRange to adjust more environment
        {
            if(i<=5) continue;                                                    // too close to ooxx
            retrace_low = Low[iLowest(Symbol(), 0, MODE_LOW, i, 1)];             // first retracement
            break_up = high_last;
            wait_buy = true;
            Print(High[i],"---------------------------break_up:",break_up);
            return;
        }
    }

    //TODO performence
    for(i=2; i<50; i++)
    {
        if(wait_sell)   break;
        if(low_last-Low[i]>2*Point)   break;
        //if(MathAbs(low_last-Low[i])<=5*Point)
        if(low_last-Low[i]<=2*Point && Low[i]-low_last<=5*Point)
        {
            if(i<5) continue;
            retrace_high = High[iHighest(Symbol(), 0, MODE_HIGH, i, 1)];
            break_down = low_last;
            wait_sell = true;
            Print(i,"---------------------------break_down:",break_down);
            return;
        }
    }
}

void ReadyForMakeMoney()
{
    double sl, tp;
    int ret;
    if(wait_buy)
    {
        if(Low[0]<retrace_low || (High[0]>break_up && High[1]==break_up))           //Second Rule:second retrace is higher than first
        {
            Print("---------------------PASS!2th retrace:",Low[0], "less than first:",retrace_low);
            break_up = 0;
            retrace_low = 0;
            wait_buy = false;
            return;
        }
        if(Bid - break_up > 10*Point)
        {
            if(High[1]!=break_up && High[2]!=break_up && High[3]!=break_up)
            {
                sl = break_up - retrace_low;
                sl = 60*Point;
                tp = 3*sl;
                Print("----------break_up:",break_up,"-----------retrace_low:",retrace_low);
                ret = OrderSend(Symbol(), OP_BUY, Lots, Ask, 1, Bid-sl, Bid+tp, "comment", MagicNum, 0, Green);
            }else{
                Print("---------------------PASS!too close to breakup!");
            }
            wait_buy = false;
            break_up = 0;
            retrace_low = 0;
            return;
        }
    }
    //
    if(wait_sell)
    {
        if(High[0]>retrace_high || (Low[0]<break_down && Low[1]==break_down))
        {
            Print("---------------------PASS!2th retrace:",High[0], "more than first:",retrace_high);
            retrace_high = 0;
            break_down = 0;
            wait_sell = false;
            return;
        }
        if(break_down-Bid>10*Point)
        {
            if(Low[1]!=break_down && Low[2]!=break_down && Low[3]!=break_down)
            {
                sl = retrace_high - break_down;
                sl = 60*Point;
                tp = 3*sl;
                Print("----------break_down:",break_down,"-----------retrace_high:",retrace_high);
                ret = OrderSend(Symbol(), OP_SELL, Lots, Bid, 1, Ask+sl, Ask-tp, "comment", MagicNum, 0, Red);
            }
            else{
                Print("---------------------PASS!too close to breakdown!");
            }
            wait_sell = false;
            retrace_high = 0;
            break_down = 0;
            return;
        }
    }
}
