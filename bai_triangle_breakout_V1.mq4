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
#define C_FREE 0
#define C_BUY 1
#define C_SELL 2
//------------------------------
// INPUT
//------------------------------
extern double    Lots = 0.1;
//------------------------------
// Global
//------------------------------
struct candidate
{
    double rs;                  //price of resistant or support(one side of triangle)
    double retrace;             //first retracement
    int direct;                 // 0-free 1-buy 2-sell
};
candidate candidates[5];        // 5 candidates
int MagicNum = 5522250;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    for(int i=0; i<ArrayRange(candidates, 0); i++)
    {
        candidates[i].rs = 0;
        candidates[i].retrace = 0;
        candidates[i].direct = 0;
    }
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    /**
    CalcuteAvgRange();
    Comment("bai_trangle_breakout_V1 EA\n",
            "Average Range in 5 5MIN_Bars:", AvgRange_5B, "\n",
            "Average Range in 10 5MIN_Bars:", AvgRange_10B, "\n");
    **/

    ReadyForMakeMoney();                                            //Entry Market anytime
    if(Volume[0]>1) return;
    DetectDoublePeak();                                             //Detect everyone new bars
  }
//+------------------------------------------------------------------+
double CalcuteAvgRange(int cal_bars)
{
    int i;
    double sum = 0;
    for(i=1; i<cal_bars+1; i++)
    {
        sum += (High[i]-Low[i]);
    }
    return sum/cal_bars;
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
    int i, j;
    double high_last = High[1];
    double low_last = Low[1];
    double retrace_low, retrace_high;
    
    for(i=2; i<50; i++)
    {
        if(High[i]-high_last>2*Point) break;
        if(high_last-High[i]<=5*Point && High[i]-high_last<=2*Point)             //TODO may use AverageRange to adjust more environment
        {
            if(i<=5) continue;                                                   // too close to ooxx
            retrace_low = Low[iLowest(Symbol(), 0, MODE_LOW, i, 1)];             // first retracement
            
            if(high_last-retrace_low<2*CalcuteAvgRange(i)) continue;            // Here need a fairly bounce(twice than AverageRange)

            for(j=0; j<5; j++)
            {
                if(candidates[j].direct == C_FREE)
                {
                    candidates[j].rs = high_last;
                    candidates[j].retrace = retrace_low;
                    candidates[j].direct = C_BUY;
                    Print("---------------------------buy candidate:",candidates[j].rs);
                    break;
                }
            }
            return;
        }
    }

    //TODO performence
    for(i=2; i<50; i++)
    {
        if(low_last-Low[i]>2*Point)   break;
        if(low_last-Low[i]<=2*Point && Low[i]-low_last<=5*Point)
        {
            if(i<5) continue;
            retrace_high = High[iHighest(Symbol(), 0, MODE_HIGH, i, 1)];
            if(retrace_high-low_last<2*CalcuteAvgRange(i)) continue;
            for(j=0; j<5; j++)
            {
                if(candidates[j].direct == C_FREE)
                {
                    candidates[j].rs = low_last;
                    candidates[j].retrace = retrace_high;
                    candidates[j].direct = C_SELL;
                    Print("---------------------------sell candidate:",candidates[j].rs);
                    break;
                }
            }
            return;
        }
    }
}

void ReadyForMakeMoney()
{
    double sl, tp;
    int i, ret;
    for(i=0; i<ArrayRange(candidates, 0); i++)
    {
        if(candidates[i].direct==C_BUY)
        {
            if(Low[0]<candidates[i].retrace || (High[0]>candidates[i].rs && High[1]==candidates[i].rs))           //Second Rule:second retrace is higher than first
            {
                Print("---------------------PASS!2th retrace:",Low[0], "less than first:",candidates[i].retrace);
                candidates[i].retrace = 0;
                candidates[i].rs = 0;
                candidates[i].direct = C_FREE;
                return;
            }
            if(Bid - candidates[i].rs > 10*Point)
            {
                if(High[1]!=candidates[i].rs && High[2]!=candidates[i].rs && High[3]!=candidates[i].rs)
                {
                    sl = candidates[i].rs - candidates[i].rs;
                    sl = 60*Point;
                    tp = 3*sl;
                    Print("----------break_up:",candidates[i].rs,"-----------retrace_low:",candidates[i].rs);
                    ret = OrderSend(Symbol(), OP_BUY, Lots, Ask, 1, Bid-sl, Bid+tp, "comment", MagicNum, 0, Green);
                }else{
                    Print("---------------------PASS!too close to breakup!");
                }
                candidates[i].direct = C_FREE;
                candidates[i].retrace = 0;
                candidates[i].rs = 0;
                return;
            }
        }
        else if(candidates[i].direct==C_SELL)
        {
            if(High[0]>candidates[i].retrace || (Low[0]<candidates[i].rs && Low[1]==candidates[i].rs))
            {
                Print("---------------------PASS!2th retrace:",High[0], "more than first:",candidates[i].retrace);
                candidates[i].retrace = 0;
                candidates[i].rs = 0;
                candidates[i].direct = C_FREE;
                return;
            }
            if(candidates[i].rs-Bid>10*Point)
            {
                if(Low[1]!=candidates[i].rs && Low[2]!=candidates[i].rs && Low[3]!=candidates[i].rs)
                {
                    sl = candidates[i].retrace - candidates[i].rs;
                    sl = 60*Point;
                    tp = 3*sl;
                    Print("----------break_down:",candidates[i].rs,"-----------retrace_high:",candidates[i].retrace);
                    ret = OrderSend(Symbol(), OP_SELL, Lots, Bid, 1, Ask+sl, Ask-tp, "comment", MagicNum, 0, Red);
                }
                else{
                    Print("---------------------PASS!too close to breakdown!");
                }
                candidates[i].direct = C_FREE;
                candidates[i].retrace = 0;
                candidates[i].rs = 0;
                return;
            }
        }
    }
}
