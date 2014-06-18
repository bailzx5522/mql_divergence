//+------------------------------------------------------------------+
//|                                                      bai_FTD.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
extern version = "Bailingzhou FTD ver1.0 step.";
//Input
extern string _comment1 = "Manipulate settings";
extern bool manipulate  = false;
extern int type         = 0;                             // 0:buy 1:sell
extern double price     = 0;
extern string _comment2 = "GRID settings";
extern double lots      = 0.01;
extern int ProfitTarget = 40;							// Minimum profit target in pips
extern int increment    = 50;							// pips between levels
extern int levels       = 3;							// number of levels of pending orders
extern string _comment3 = "martingale settings"
//Global
int decision = 0;

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
   if(manipulate)
   {
      MakeOrders();
      return;
   }
   GetAvgRange();
   GetSRLevel();
   MakeDesicion();
   MakeOrders();
}
//+------------------------------------------------------------------+

void MakeDesicion()
{
}

void MakeOrders()
{
    int i;
}


void GetAvgRange()
{
}


//+------------------------------------------------------------------+
//| Get Resistant/Support Level 		                             |
//+------------------------------------------------------------------+
void GetSRLevel()
{
}
