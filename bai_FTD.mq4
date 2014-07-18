//+------------------------------------------------------------------+
//|                                                      bai_FTD.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|Author:bailingzhou                                                |
//|Version v1.00                                                     |
//|   initial version                                                |
//|Version v1.10                                                     |
//|   Add hedge while a "fairly" trend performing                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.10"
#property strict
//
#define BUY  1
#define SELL  2
//
extern string version = "Bailingzhou FTD ver1.0 step.";
//Input
extern bool      use_bb = true;
extern int       bb_period = 20;
extern int       bb_deviation = 2;
extern int       bb_shift = 0;
extern double    BaseLot = 0.01;

extern string    _comment1 = "0 = Use Default Settings";
extern int       TakeProfit = 0;
extern int       MaxSpread = 0;
extern int       MaxTotalVol = 0;
extern int       MaxGrid = 10;
extern int       GridSize = 50;
extern int       GridProfit = 200;

extern int times = 9999;
extern bool	_EnableAutoBuy	= true;
extern bool	_EnableAutoSell= true;
//Global
int MagicNum = 20140629;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   if(TakeProfit == 0)
   {
      if(StringFind(Symbol(),"EURUSD") >=0){
         TakeProfit	= 100;
		} else if (StringFind(Symbol(),"USDJPY") >=0) {
			TakeProfit	= 100;
		} else if (StringFind(Symbol(),"GBPUSD") >=0) {
			TakeProfit	= 200;
		} else if (StringFind(Symbol(),"EURJPY") >=0) {
			TakeProfit	= 200;
		} else if (StringFind(Symbol(),"GBPJPY") >=0) {
			TakeProfit	= 300;
		} else {
			TakeProfit	= 100;
		}
   }
   
   if(MaxSpread == 0)
   {
      MaxSpread = 15;
   }
   if(MaxTotalVol == 0)
   {
      MaxTotalVol = 999;
   }
//---
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
   ManageBuy();
   ManageSell();
   //Display();
}
//+------------------------------------------------------------------+
double spread() {
	double s = (Ask - Bid) / Point;
	return(s);
}
double MaxVol() {
	return(MarketInfo(Symbol(),MODE_MAXLOT));
}

double CalNextPos(double v, int i)
{
   // 50,60,70...
   return NormalizeDouble(v+GridSize+10*(i-1)*Point, Digits);
}

double CalNextVol(double v)
{
   return NormalizeDouble(1.2*v, 3);
}

void ManageBuy()
{
   double TP = Ask;
   double SL = 0;
   double TotalVol = 0;
   double TotalProfit = 0;
   double ThisVol = 0;
   double ThisPos = 0;
   double AvgPrice = Ask;
   double FirstPrice = 0;
   int i, ret;
   int count = 0;
   int FirstOrder	= int(TimeCurrent());
   
   //Calculate
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) && OrderType()==OP_BUY && Symbol()==OrderSymbol() && OrderMagicNumber()==MagicNum)
      {
         // Should be stoploss, do not open orders
    		if (OrderStopLoss() > 0 && OrderStopLoss()>=Bid) {
				_EnableAutoBuy = false;
			}
         AvgPrice = (AvgPrice*TotalVol+OrderOpenPrice()*OrderLots()) / (TotalVol+OrderLots());
         TP = (TP*TotalVol + OrderTakeProfit()*OrderLots()) / (TotalVol+OrderLots());
         SL = (SL*TotalVol + OrderStopLoss()*OrderLots()) / (TotalVol+OrderLots());
         TotalVol = TotalVol + OrderLots();
         TotalProfit = TotalProfit + OrderProfit();
         if(OrderOpenTime()<FirstOrder)
         {
            FirstOrder = OrderOpenTime();
            FirstPrice = OrderOpenPrice();
         }
         
         count++;
      }
   }
   
   RefreshRates();
   if(MaxSpread>spread() && TotalVol<MaxTotalVol && times > 0)
   {
      double PriceDistance = (AvgPrice-Ask)/Point;
      
      if (TotalVol == 0 && _EnableAutoBuy && MakeDecision()==BUY)
      {
			ThisVol = BaseLot;
			ret = OrderSend(Symbol(), OP_BUY, ThisVol, Ask, 1, 0, 0, NULL, MagicNum, 0);
			for(i=1; i<MaxGrid; i++)
			{
			   ThisPos = CalNextPos(ThisPos, i);
			   ThisVol = CalNextVol(ThisVol);

			   ret = OrderSend(Symbol(), OP_BUYLIMIT , ThisVol, Ask-ThisPos, 1, 0, 0, NULL, MagicNum, 0);
			}
			times--;
		}
   }
   
   // Profit reached, close open & delete pending.
   RefreshRates();
   if(TotalVol > 0 && Bid-AvgPrice>GridProfit*Point)
	{
	   for(i=OrdersTotal()-1; i>=0; i--)
	   {
	      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNum && OrderType()==OP_BUY )
	      {
	         ret = OrderClose(OrderTicket(), OrderLots(), Bid, 1, 0);
	      }
	      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNum && OrderType()==OP_BUYLIMIT )
	      {
	         ret = OrderDelete(OrderTicket(), 0);
	      }
      }
	}
}

void ManageSell()
{
   double TP = Bid;
   double SL = 0;
   double TotalVol = 0;
   double TotalProfit = 0;
   double ThisVol = 0;
   double ThisPos = 0;
   double AvgPrice = Bid;
   double FirstPrice = 0;
   int i, ret;
   int count = 0;
   int FirstOrder	= int(TimeCurrent());
   
   //Calculate
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS,MODE_TRADES) && OrderType()==OP_SELL && Symbol()==OrderSymbol() && OrderMagicNumber()==MagicNum)
      {
         // Should be stoploss, do not open orders
    		if (OrderStopLoss() > 0 && OrderStopLoss()<=Ask) {
				_EnableAutoSell = false;
			}
         AvgPrice = (AvgPrice*TotalVol+OrderOpenPrice()*OrderLots()) / (TotalVol+OrderLots());
         TP = (TP*TotalVol + OrderTakeProfit()*OrderLots()) / (TotalVol+OrderLots());
         SL = (SL*TotalVol + OrderStopLoss()*OrderLots()) / (TotalVol+OrderLots());
         TotalVol = TotalVol + OrderLots();
         TotalProfit = TotalProfit + OrderProfit();
         if(OrderOpenTime()<FirstOrder)
         {
            FirstOrder = OrderOpenTime();
            FirstPrice = OrderOpenPrice();
         }
         
         count++;
      }
   }
   
   RefreshRates();
   if(MaxSpread>spread() && TotalVol<MaxTotalVol && times>0)
   {
      
      double PriceDistance = (Bid-AvgPrice)/Point;
      if (TotalVol == 0 && _EnableAutoSell && MakeDecision()==SELL)
      {
         ThisVol = BaseLot;
			ret = OrderSend(Symbol(), OP_SELL, ThisVol, Bid, 1, 0, 0, NULL, MagicNum, 0);
			for(i=1; i<MaxGrid; i++)
			{
			   ThisVol = CalNextVol(ThisVol);
			   ThisPos = CalNextPos(ThisPos, i);
			   ret = OrderSend(Symbol(), OP_SELLLIMIT , ThisVol, Bid+ThisPos, 1, 0, 0, NULL, MagicNum, 0);
			}
			times--;
		}
   }
   
   RefreshRates();
   if(TotalVol > 0 && AvgPrice-Ask>GridProfit*Point)
	{
	   for(i=OrdersTotal()-1; i>=0; i--)
	   {
	      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNum && OrderType()==OP_SELL )
	      {
	         ret = OrderClose(OrderTicket(), OrderLots(), Ask, 1, 0);
	      }
	      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNum && OrderType()==OP_SELLLIMIT )
	      {
	         ret = OrderDelete(OrderTicket(), 0);
	      }
      }
	}
}

int MakeDecision()
{
   // running on 1H TF. Maybe run on 15M and reference on 1H
   int tf = PERIOD_H1;
   double upBB = iBands(Symbol(), tf, bb_period, bb_deviation, 0, PRICE_CLOSE, MODE_UPPER, bb_shift);
   double loBB = iBands(Symbol(), tf, bb_period, bb_deviation, 0, PRICE_CLOSE, MODE_LOWER, bb_shift);

   if(use_bb)
   {
      if(High[bb_shift]>upBB) return(SELL);
      if(Low[bb_shift]<loBB)  return(BUY);
   }
   return(0);
}

// display some comments
void Display()
{
   Comment("");
}
