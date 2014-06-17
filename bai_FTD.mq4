//+------------------------------------------------------------------+
//|                                                      bai_FTD.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

extern input manipulate = false;
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
}


void GetAvgRange()
{
}


void GetSRLevel()
{
}
