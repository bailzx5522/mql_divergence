//+------------------------------------------------------------------+
//|                                             bai_midnight_FTD.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

#define BUY_OPEN 1
#define SELL_OPEN 2
#define BUY_CLOSE 3
#define SELL_CLOSE 4
#define FREE 0
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
extern int StartTime = 0;
extern int EndTime   = 0;

//+------------------------------------------------------------------+
//| Global parameters                                                 |
//+------------------------------------------------------------------+
double RangeTop = 0;
double RangeBottom = 0;
string Text;
int MagicNum = 20140728;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   if(StartTime == 0 && EndTime == 0)
   {
      // from 20:00 ~ 7:00(EEST +3)
      StartTime = 20;
      EndTime = 7;
   }
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
   Text = "bailingzhou scalper EA running in midnight @FTD";
   CalRange();
   MakeMoney();
   Display(Text);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate Range in order to set SL/TP                            |
//+------------------------------------------------------------------+
void CalRange()
{
   // First Hour
   if(TimeHour(TimeCurrent()) == 20)
   {
      RangeTop = iHighest(Symbol(), PERIOD_H1, MODE_HIGH, 2, 0);
      RangeBottom = iHighest(Symbol(), PERIOD_H1, MODE_LOW, 2, 0);
   }else{
      RangeTop = MathMax(RangeTop, iHigh(Symbol(), PERIOD_H1, 0));
      RangeBottom = MathMin(RangeBottom, iLow(Symbol(), PERIOD_H1,0));
   }
   Text = Text + "\nRangeTop: "+DoubleToStr(RangeTop, 5) +
                 "\nRangeBottom: "+DoubleToStr(RangeBottom, 5);
}

//+------------------------------------------------------------------+
//| Start from 20:00 to 7:00 EEST                                    |
//+------------------------------------------------------------------+
bool WorkTime()
{
   datetime t = TimeCurrent();
   datetime lt = TimeLocal();
   int h = TimeHour(t);
   int lh = TimeHour(lt);
   if(lh-h == 3)
   {
      Print("Local time +8, and server time is EEST.");
   }else{
      return false;
   }

   if(h >= StartTime || h <= EndTime)          
   {
      return true;
   }
   return false;
}

void MakeMoney()
{
   int i = 0;
   int TotalVol = OrdersTotal();
   
   if(WorkTime())
   {
      if(TotalVol>0)
      {
         // Check opened orders.I don't TRUST order's SL/TP. I prefer to dynamic check profit.
         for(i=0; i<TotalVol; i++)
         {
            Print("11111111111111");
         }
      }
      // Get ready to open orders.
      if(MakeDecision() == BUY_OPEN)
      {
         OrderSend();
      }else if(MakeDecision() == SELL_OPEN){
         OrderSend();
      }
      
      
   }else if(TotalVol > 0){
      //close all orders.

      return;
   }
}

void Display(string t)
{
   Comment(t);
}

int MakeDecision()
{
   double sar = iSAR(Symbol(), PERIOD_M1, 0.02, 0.2, 0);
   double ma = iMA(Symbol(), PERIOD_M1, 14, 0, MODE_SMA, PRICE_CLOSE, 0);
   double bb_upper = iBands(Symbol(), PERIOD_M1, 20, 2, 0, PRICE_HIGH, MODE_UPPER,  0);
   double bb_lower = iBands(Symbol(), PERIOD_M1, 20, 2, 0, PRICE_LOW, MODE_LOWER,  0);  
   
   if(Ask>sar && Ask<ma && Ask<bb_lower)
   {
      return BUY_OPEN;
   }else if(Bid < sar && Bid > ma && Bid > bb_upper){
      return SELL_OPEN;
   }
   return FREE;
}
