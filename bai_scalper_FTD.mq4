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
extern int    StartTime = 0;
extern int    EndTime   = 0;
extern double BaseVol   = 0.1;
extern double MinTP     = 50;
extern bool   MM = false;
//+------------------------------------------------------------------+
//| Global parameters                                                 |
//+------------------------------------------------------------------+
double RangeTop = 0;
double RangeBottom = 0;
double BbDistance = 0;
string Text;
int MagicNum = 20140728;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   if(MM == true)
   {
      MoneyManage();
   }
   if(StartTime == 0 && EndTime == 0)
   {
      // from 20:00 ~ 7:00(EEST +3)
      StartTime = 20;
      EndTime = 7;
   }
   /**
   // Only use while set TP/SL
   if(MinTP < MarketInfo(Symbol(), MODE_STOPLEVEL))
   {
      MinTP = MarketInfo(Symbol(), MODE_STOPLEVEL);
   }
   **/
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
   ManageBuy();
   ManageSell();
   Display(Text);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate Range in order to set SL/TP                            |
//+------------------------------------------------------------------+
void CalRange()
{
   // First Hour
   if(TimeHour(TimeCurrent()) == StartTime)
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
   // Beijing+8 EEST +3
   datetime t = TimeCurrent();
   datetime lt = TimeLocal();
   datetime gmt = TimeGMT();
   int h = TimeHour(t);
   int lh = TimeHour(lt);
   Text = Text + "\nServer Time: "+ IntegerToString(t) +
                 "\nLocal Time: " + IntegerToString(lt);

   if(h >= StartTime || h <= EndTime)          
   {
      return true;
   }
   return false;
}

double CalVol(double v)
{
   return 1.5*v;
   //return v;
}

void ManageBuy()
{
   int i = 0;
   int ret;
   int Orders = OrdersTotal();
   int count = 0;
   double TotalProfit = 0;
   double TotalLoss = 0;
   double TotalVol = 0;
   double AvgPrice = 99999;
   double ThisVol = BaseVol;
   double TP = 0;
   double SL = 0;
   double LastOrderPrice = 99999;
   double LastOrderVol = 0;

   for(i=0; i<Orders; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) &&  OrderType()==OP_BUY && Symbol()==OrderSymbol() && OrderMagicNumber()==MagicNum)
      {
         AvgPrice = (AvgPrice*TotalVol+OrderOpenPrice()*OrderLots()) / (TotalVol+OrderLots());
         //TP = (TP*TotalVol + OrderTakeProfit()*OrderLots()) / (TotalVol+OrderLots());
         //SL = (SL*TotalVol + OrderStopLoss()*OrderLots()) / (TotalVol+OrderLots());
         TotalVol = TotalVol + OrderLots();
         TotalProfit = TotalProfit + OrderProfit();
         LastOrderPrice = MathMin(LastOrderPrice, OrderOpenPrice());
         LastOrderVol = MathMax(LastOrderVol, OrderLots());
         count++;
      }
   }
   
   if(count==0 && MakeDecision(true)==BUY_OPEN && WorkTime())
   {
      //TP = Bid + MathMax(BbDistance, MinTP*Point);
      //ret = OrderSend(Symbol(), OP_BUY, ThisVol, Ask, 1, NULL, NormalizeDouble(TP, Digits), "First Buy", MagicNum);
      //Print("----first buy-----OpenOrder:",Ask,"---",ThisVol);
      ret = OrderSend(Symbol(), OP_BUY, ThisVol, Ask, 1, NULL, NULL, "First Buy", MagicNum);
      return;
   }
   
   // Target touched!
   if(count>0)
   {
      //if(Bid-AvgPrice > 40*Point || (!WorkTime() && Bid-AvgPrice > 0) || (TimeHour(TimeCurrent())==10))
      if(Bid-AvgPrice > MinTP*Point || (!WorkTime() && Bid-AvgPrice > 0))
      {
         for(i=0; i<Orders; i++)
         {
            if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) &&  OrderType()==OP_BUY && Symbol()==OrderSymbol() && OrderMagicNumber()==MagicNum)
            {
               //Print("---------CloseOrder:",Bid,"---",OrderLots());
               ret = OrderClose(OrderTicket(), OrderLots(), Bid, 1, 0);
            }
         }
      }else if(LastOrderPrice - Ask > MathMax(BbDistance, 50*Point)  && WorkTime()){
         ThisVol = CalVol(LastOrderVol);
         //Print("---------OpenOrder:",Ask,"---",NormalizeDouble(ThisVol, 2));
         ret = OrderSend(Symbol(), OP_BUY, NormalizeDouble(ThisVol, 2), Ask, 1, NULL, NULL, "Addition Buy", MagicNum);
      }
   }
}

void ManageSell()
{
   int i = 0;
   int ret;
   int Orders = OrdersTotal();
   int count = 0;
   double TotalProfit = 0;
   double TotalLoss = 0;
   double TotalVol = 0;
   double AvgPrice = 99999;
   double ThisVol = BaseVol;
   double TP = 0;
   double SL = 0;
   double LastOrderPrice = 0;
   double LastOrderVol = 0;

   for(i=0; i<Orders; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) &&  OrderType()==OP_SELL && Symbol()==OrderSymbol() && OrderMagicNumber()==MagicNum)
      {
         AvgPrice = (AvgPrice*TotalVol+OrderOpenPrice()*OrderLots()) / (TotalVol+OrderLots());
         //TP = (TP*TotalVol + OrderTakeProfit()*OrderLots()) / (TotalVol+OrderLots());
         //SL = (SL*TotalVol + OrderStopLoss()*OrderLots()) / (TotalVol+OrderLots());
         TotalVol = TotalVol + OrderLots();
         TotalProfit = TotalProfit + OrderProfit();
         LastOrderPrice = MathMax(LastOrderPrice, OrderOpenPrice());
         LastOrderVol = MathMax(LastOrderVol, OrderLots());
         count++;
      }
   }
   
   if(count==0 && MakeDecision(true)==SELL_OPEN && WorkTime())
   {
      //TP = Ask - MathMax(BbDistance, MinTP*Point);
      //ret = OrderSend(Symbol(), OP_BUY, ThisVol, Bid, 1, NULL, NormalizeDouble(TP, Digits), "First Sell", MagicNum);
      //Print("---------first sell OpenOrder:",Bid,"---",ThisVol);
      ret = OrderSend(Symbol(), OP_SELL, ThisVol, Bid, 1, NULL, NULL, "First Sell", MagicNum);
      return;
   }
   
   // Target touched!
   if(count > 0)
   {
      //if(AvgPrice-Ask > 40*Point || (!WorkTime() && AvgPrice-Ask > 0) || (TimeHour(TimeCurrent())==10))
      if(AvgPrice-Ask > MinTP*Point || (!WorkTime() && AvgPrice-Ask > 0))
      {
         for(i=0; i<Orders; i++)
         {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) &&  OrderType()==OP_SELL && Symbol()==OrderSymbol() && OrderMagicNumber()==MagicNum)
            {
               ret = OrderClose(OrderTicket(), OrderLots(), Ask, 1, 0);
            }
         }
      }else if(Bid - LastOrderPrice > MathMax(BbDistance, 50*Point) && WorkTime()){
         ThisVol = CalVol(LastOrderVol);
         //Print("---------sell OpenOrder:",Bid,"---",NormalizeDouble(ThisVol, 2));
         ret = OrderSend(Symbol(), OP_SELL, NormalizeDouble(ThisVol, 2), Bid, 1, NULL, NULL, "Addition Sell", MagicNum);
      }
   }
}

void Display(string t)
{
   Comment(t);
}

int MakeDecision(bool open)
{
   double sar = iSAR(Symbol(), PERIOD_M1, 0.02, 0.2, 0);
   double ma = iMA(Symbol(), PERIOD_M1, 14, 0, MODE_SMA, PRICE_CLOSE, 0);
   double bb_upper = iBands(Symbol(), PERIOD_M1, 20, 2, 0, PRICE_HIGH, MODE_UPPER,  0);
   double bb_lower = iBands(Symbol(), PERIOD_M1, 20, 2, 0, PRICE_LOW, MODE_LOWER,  0);
   BbDistance = bb_upper - bb_lower;
   /**
   if(Ask>sar && Ask<ma && Ask<bb_lower)
   {
      return BUY_OPEN;
   }else if(Bid < sar && Bid > ma && Bid > bb_upper){
      return SELL_OPEN;
   }
   return FREE;
   **/
   // Make desicion of open order
   if( open && Bid > bb_upper )
   {
      return SELL_OPEN;
   }else if( open && Ask < bb_lower )
   {
      return BUY_OPEN;
   }
   
   // Make desicion of close order
   if( !open && Ask<bb_lower)
   {
      return SELL_CLOSE;
   }else if(!open && Bid>bb_upper)
   {
      return BUY_CLOSE;
   }
   return FREE;
}

//
void MoneyManage()
{
   double balance = AccountBalance();
   double margin = AccountFreeMargin();
   double leverage = AccountLeverage();
   
   return;
   
}
