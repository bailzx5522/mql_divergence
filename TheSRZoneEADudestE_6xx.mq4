//find the system/updates at http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=5&t=3343
// http://www.stevehopwoodforex.com
// "Feeling generous? Help keep the coder going with a small Paypal donation to pianodoodler@hotmail.com"
//Strategy by dudest
//coded by milanese, thanks to Steve Hopwood, phil_trade,SS_SupportResistance (code by Andrew Sumner thank you for this great Indi!!), baluda for the great CSS lib and much other's for ideas that are integrated in my shell
//please do not publish this outside of http://www.stevehopwoodforex.com

#property copyright "Copyright © 2014, milanese (Tommaso),Andrew Sumner(Indicator), Steve Hopwood et. al."
#property link      "http://SteveHopwoodForex.com"

#include <stdlib.mqh>

#define  NL    "\n"
string          Gap,ScreenMessage;
#define version "TheSRZoneEA 0.7.0"
//Slope constants
#define  buyonly "Buy Only. "
#define  sellonly "Sell Only. "
#define  buyhold "Buy and hold. "
#define  sellhold "Sell and hold. "
#define  rising   "Angle is rising. "
#define  falling   "Angle is falling. "
#define  unchanged   "Angle is unchanged. "
#define  ranging   "Slope is ranging. "
#define SSSR_ZONE_WEAK         0
#define SSSR_ZONE_TURNCOAT     1
#define SSSR_ZONE_UNTESTED     2
#define SSSR_ZONE_VERIFIED     3
#define SSSR_ZONE_PROVEN       4

#define SSSR_UP   1
#define SSSR_NONE 0
#define SSSR_DN  -1

#define SSSR_FAST 1
#define SSSR_SLOW 2

#define SSSR_ZONE_SUPPORT 1
#define SSSR_ZONE_RESIST  2




#define SSSR_UP_POINT       1
#define SSSR_DN_POINT      -1




extern string  ishi="**** Indicator settings ****";

extern int PERIOD_SR=PERIOD_M30;
extern int PERIOD_2CandleRule=PERIOD_H4;
extern int PERIOD_ATR=PERIOD_H4;
extern int MinHitsForUsingZone=2;
extern string   slp="--TMA-SlopeSettings--";
extern int      HtfTimeFrame=240;//Zero to disable
extern double   HtfBuyOnlyLevel=0.2;
extern double   HtfBuyHoldLevel=0.8;
double   HtfBuyCloseLevel=0.3;
extern double   HtfSellOnlyLevel=-0.2;
extern double   HtfSellHoldLevel=-0.8;
double   HtfSellCloseLevel=-0.3;
int      LtfTimeFrame=0;//Zero to disable
double   LtfBuyOnlyLevel=0.4;
double   LtfBuyHoldLevel=0.8;
double   LtfBuyCloseLevel=0.3;
double   LtfSellOnlyLevel=-0.4;
double   LtfSellHoldLevel=-0.8;
double   LtfSellCloseLevel=-0.3;
////////////////////////////////////////////////////////////////////////////////////////
double          HtfSlopeVal[8],LtfSlopeVal,PrevHtfSlopeVal,PrevLtfSlopeVal;
string          HtfSlopeTrend,LtfSlopeTrend,HtfSlopeAngle,LtfSlopeAngle;
double          SR_TP=0;

extern string  gshi="**** General settings ****";

extern int     MagicNumber=99;
extern int     slippage=1;
extern double  AdvertisedSpread=3.0; // Put here the avarage spread for the pair from your broker
bool    UseFixedLot=true;
extern double  FixedLot=0.1;
extern double  StackLot=0.1;
extern double  BufferPips=45;
double BufferPipsOpen=10;
extern bool    AddAdditionalPositionsInTrend=false;
extern int     MaxAdditionalPositions=0;
extern double  MinTPProfitInUSD=15;
////////////////////////////////////////////////////////////////////////////////////////
extern string  pcbe="PartClose settings can be used in";
extern string  pcbe1="conjunction with BE/SL settings";
extern int     PartClosePercent=50;
extern bool    PartCloseWithMovingSLMain=false;
extern bool    PartCloseWithMovingSLStack=true;
double JumpProfit=0;
double JumpProfitST=0;
double SetBEminPip=0;
double SetBEminPipST=0;


double adr=0;

double  Risk_percent=3;
double   LotStep,MinLot,MaxLot;

//double   WeeklyPivot,DailyPivot,YesterdayPivot,TwoBeforedayPivot;
double   ma1[8],ma2[8],ma3[8],ma4[8];
double   rsi8[8];
double HighValue=0;
double LowValue=0;
int Order_Select=0;

extern bool    Use_SetBEAndJump=true;
extern double  SecureProfit=4;
extern double  BeVarPercent=55;
double BeVar=0;

extern double  SecureProfitST=4;

extern bool    UseCloseFriday=false;

int DeltaTimeHistoTrades=14400;
int DeltaTimeLiveTrades=14400;
bool     BrokerHasSundayCandle=false;

extern double   RequiredMarginPercentile=1000;

//CSS Integration
extern string    CSSInput="----CCS inputs----";
extern bool     UseCSS=false;
extern bool     UseCSSForEntry=false;
extern bool     UseCSSForTP=false;

extern int      maxBars=100;
extern int      CssTf=240;//Defaults to current time frame
string          CurrNames[8]={ "USD","EUR","GBP","CHF","JPY","AUD","CAD","NZD" };
////////////////////////////////////////////////////////////////////////////////////////
string          Curr1,Curr2;//First and second currency in the pair
int             CurrIndex1,CurrIndex2;//Index of the currencies that form the pair to point to the correct one in currencyNames
double          CurrVal1[8],CurrVal2[8];//Hold the values of the two currencies, allowing me to look back in time to see if the currency is rising or falling.
string          CurrDirection1,CurrDirection2;//One of the Currency ststus constants
int CSS_Allowed_Buy=1;
int CSS_Allowed_Sell=1;
#define  upaccelerating "Up, and accelerating"
#define  updecelerating "Up, but slowing"
#define  downaccelerating "Down, and accelerating"
#define  downdecelerating "Down, but slowing"

bool zone_solid=false;
int zone_linewidth=1;
int zone_style=0;
bool zone_show_info=true;
int zone_label_shift=5;
bool zone_merge=true;
bool zone_extend=true;
color color_support_weak     = DarkSlateGray;
color color_support_untested = SeaGreen;
color color_support_verified = Green;
color color_support_proven   = LimeGreen;
color color_support_turncoat = OliveDrab;
color color_resist_weak      = Indigo;
color color_resist_untested=Orchid;
color color_resist_verified  = Crimson;
color color_resist_proven    = Red;
color color_resist_turncoat  = DarkOrange;


bool BuyOk=false;
bool SellOk=false;

//Steve shell mandatory variables
int             O_R_Setting_max_retries=10;
double          O_R_Setting_sleep_time=4.0; /* seconds */
double          O_R_Setting_sleep_max=15.0; /* seconds */
int            RetryCount=10;//Will make this number of attempts to get around the trade context busy error.
bool    BrokerIsECN=true;
bool           TakingEmergencyAction;
int            TicketNo=-1,OpenTrades;
//end of Steve shell mandatory variables

bool SignalBuy=false;
bool SignalSell=false;
bool SignalBuyStack=false;
bool SignalSellStack=false;
double lot;

bool FlagCloseFriday=false;

int myHour=99;
int multiplier=1;
double spread=0;
int myMinute=99;
double CostPip=5;
bool TPChangeFlag=false;
int     SSSR_BackLimit   = 10000;

double  SSSR_zone_fuzzfactor = 0.9;
bool    SSSR_zone_merge = true;
bool    SSSR_zone_extend = true;

double  SSSR_zone_fastfactor = 3.0;
double  SSSR_zone_slowfactor = 6.0;

double  SSSR_FastDnPts[], SSSR_FastUpPts[];
double  SSSR_SlowDnPts[], SSSR_SlowUpPts[];

double  SSSR_zone_hi[1000], SSSR_zone_lo[1000];
int     SSSR_zone_start[1000], SSSR_zone_hits[1000], SSSR_zone_type[1000], SSSR_zone_strength[1000], SSSR_zone_count = 0;
bool    SSSR_zone_turn[1000];
string  SSSR_sym;
int     SSSR_TF;
double res_hi=0, res_lo=0, sup_hi=0, sup_lo=0;
int res_strength=0, sup_strength=0;
int sup_zone, res_zone;
bool    UsePartCloseOnTP=true;
int strenght_used_r=4;
int strenght_used_s=4;

int time_offset=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit(void)
  {

//Adapt to x digit Brokers
   if(Digits == 2 || Digits == 4) multiplier = 1;
   if(Digits == 3 || Digits == 5) multiplier = 10;
   if(Digits == 6) multiplier = 100;
   if(Digits == 7) multiplier = 1000;
   if(IsTesting()==true)
     {
      UseCSS=false;
      UseCSSForEntry=false;
      UseCSSForTP=false;
     }
SSSR_UpdateZones(false, Symbol(), PERIOD_SR);
// Special case for gold silver.
   if((StringFind(Symbol(),"XAUUSD",0)!=-1)&&(Digits==3))multiplier = 100;
   if((StringFind(Symbol(),"XAUUSD",0)!=-1)&&(Digits==2))multiplier = 10;
   if((StringFind(Symbol(),"XAUUSD",0)!=-1)&&(Digits==1))multiplier = 1;
   if((StringFind(Symbol(),"XAGUSD",0)!=-1)&&(Digits==4))multiplier = 100;
   if((StringFind(Symbol(),"XAGUSD",0)!=-1)&&(Digits==3))multiplier = 10;
   if((StringFind(Symbol(),"XAGUSD",0)!=-1)&&(Digits==2))multiplier = 1;
   BeVarPercent=BeVarPercent/100;
   if(BeVarPercent==0)BeVarPercent=1;
  

   CostPip*=multiplier;

   AdvertisedSpread*=multiplier;
   slippage*=multiplier;
   BufferPips*=multiplier;
   BufferPipsOpen*=multiplier;

   SecureProfit*=multiplier;

   SecureProfitST*=multiplier;

   LotStep= MarketInfo(Symbol(),MODE_LOTSTEP);
   MinLot = MarketInfo(Symbol(),MODE_MINLOT);
   MaxLot = MarketInfo(Symbol(),MODE_MAXLOT);
// Initialize libCSS



   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

   void OnDeinit(const int reason)
  {
   DeleteZones();
   

  }

  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {


//end indi embed
   myHour=TimeHour(TimeCurrent());
   //if (NewBar(PERIOD_SR)==true)
   SSSR_UpdateZones(true, Symbol(), PERIOD_SR);
   for(int i=0; i<SSSR_zone_count; i++)
        {
         string lbl;
         if(SSSR_zone_strength[i]==SSSR_ZONE_PROVEN)
            lbl="Proven";
         else if(SSSR_zone_strength[i]==SSSR_ZONE_VERIFIED)
            lbl="Verified";
         else if(SSSR_zone_strength[i]==SSSR_ZONE_UNTESTED)
            lbl="Untested";
         else if(SSSR_zone_strength[i]==SSSR_ZONE_TURNCOAT)
            lbl="Turncoat";
         else
            lbl="Weak";

         if(SSSR_zone_type[i]==SSSR_ZONE_SUPPORT)
            lbl=lbl+" Support";
         else
            lbl=lbl+" Resistance";

         if(SSSR_zone_hits[i]>0 && SSSR_zone_strength[i]>SSSR_ZONE_UNTESTED)
           {
            if(SSSR_zone_hits[i]==1)
               lbl=lbl+", Test Count="+SSSR_zone_hits[i];
            else
               lbl=lbl+", Test Count="+SSSR_zone_hits[i];
           }

         int adjust_hpos;
         int wbpc=WindowBarsPerChart();
         int k;

         k=Period()*60+(20+StringLen(lbl));

         if(wbpc<80)
            adjust_hpos=Time[0]+k*4;
         else if(wbpc<125)
            adjust_hpos=Time[0]+k*8;
         else if(wbpc<250)
            adjust_hpos=Time[0]+k*15;
         else if(wbpc<480)
            adjust_hpos=Time[0]+k*29;
         else if(wbpc<950)
            adjust_hpos=Time[0]+k*58;
         else
            adjust_hpos=Time[0]+k*115;

         //

         int shift=k*zone_label_shift;
         double vpos=SSSR_zone_hi[i]-(SSSR_zone_hi[i]-SSSR_zone_lo[i])/2;

         string s="SSSR#"+i+"LBL";
         ObjectCreate(s,OBJ_TEXT,0,0,0);
         ObjectSet(s,OBJPROP_TIME1,adjust_hpos+shift);
         ObjectSet(s,OBJPROP_PRICE1,vpos);
         ObjectSetText(s,StringRightPad(lbl,36," "),8,"Courier New");
         }
          res_zone = SSSR_FindZoneV2(SSSR_UP, true, Bid, res_hi, res_lo, res_strength);
          sup_zone = SSSR_FindZoneV2(SSSR_DN, true, Bid, sup_hi, sup_lo, sup_strength);
   ReadIndicators();
 

  
//CSS
   if(UseCSS==true) libCSSinit();
//initial output comment so we do not have too wait to long 
   DisplayUserFeedback();
//indicator integration

//end of indi_integration
//Sunday candle recognizing

   BrokerHasSundayCandle=false;
   for(int CC=0; CC<8; CC++)
     {
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,CC))==0)
        {
         BrokerHasSundayCandle=true;
         break;
        }
     }

   if(CountBuys(Symbol(),MagicNumber)>0 || CountSells(Symbol(),MagicNumber)>0) ManageOpenTrades();

   if(TimeMinute(TimeCurrent())!=myMinute)
     {

      spread=MarketInfo(Symbol(),MODE_SPREAD);

      if(UseFixedLot==false)
        {
         lot=CalculateLots(Risk_percent);
         //  if((StringFind(Symbol(),"XAUUSD",0)!=-1)&&(Digits==3)) lot*=0.1;
         if(lot<0.01) lot=0.01;
        }
      else lot=FixedLot;

      //Lot size and part-close idiot check for the cretins. Code provided by phil_trade. Many thanks, Philippe.
      //adjust Min_lot
      if(lot<MarketInfo(Symbol(),MODE_MINLOT))
        {
         Alert(Symbol()+" lot was adjusted to Minlot = "+DoubleToStr(MarketInfo(Symbol(),MODE_MINLOT),Digits));
         lot=MarketInfo(Symbol(),MODE_MINLOT);
        }//if (Lot < MarketInfo(Symbol(), MODE_MINLOT)) 

      LookForTrading();
      //////
      //TRADING HERE
      //////
      //Buypart
      double tp=0;
      double sl=0;

      RefreshRates();
      if(SignalBuy==true)
         if(SignalSell==false)
            if(CheckTradeAllowedMargin()==true)
               if(AllowedSpread(Symbol())==true)
                 {
                  tp=SR_TP;

                  sl=(Ask-(adr));
                  BeVar=(adr)*BeVarPercent;
                  Alert("Attempting to buy ",lot," of ",Symbol());
                  Print("Attempting to buy ",lot," of ",Symbol());
                  SendSingleTrade(Symbol(),OP_BUY,"MainTrade",lot,Ask,sl,tp);
                 }

      RefreshRates();
      if(SignalBuy==false)
         if(SignalSell==true)
            if(CheckTradeAllowedMargin()==true)
               if(AllowedSpread(Symbol())==true)
                 {
                  tp=SR_TP;

                  sl=(Bid+(adr));
                  BeVar=(adr)*BeVarPercent;
                  Alert("Attempting to sell ",lot," of ",Symbol());
                  Print("Attempting to sell ",lot," of ",Symbol());
                  SendSingleTrade(Symbol(),OP_SELL,"MainTrade",lot,Bid,sl,tp);
                 }

      RefreshRates();
      if(SignalBuyStack==true)
         if(SignalSellStack==false)
            if(CheckTradeAllowedMargin()==true)
               if(AllowedSpread(Symbol())==true)
                 {
                  tp=SR_TP;

                  sl=(Ask-(adr*1));
                  BeVar=(adr*1)*BeVarPercent;
                  Alert("Attempting to buy ",StackLot," of ",Symbol());
                  Print("Attempting to buy ",StackLot," of ",Symbol());
                  SendSingleTrade(Symbol(),OP_BUY,"StackTrade",StackLot,Ask,sl,tp);
                 }

      RefreshRates();
      if(SignalBuyStack==false)
         if(SignalSellStack==true)
            if(CheckTradeAllowedMargin()==true)
               if(AllowedSpread(Symbol())==true)
                 {
                  tp=SR_TP;

                  sl=(Bid+(adr*1));
                  BeVar=(adr*1)*BeVarPercent;
                  Alert("Attempting to sell ",StackLot," of ",Symbol());
                  Print("Attempting to sell ",StackLot," of ",Symbol());
                  SendSingleTrade(Symbol(),OP_SELL,"StackTrade",StackLot,Bid,sl,tp);
                 }

      DisplayUserFeedback();
      myMinute=TimeMinute(TimeCurrent());
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateLots(double risk_percent)
  {
   int SL=300;
   double risk_value;

   risk_value=AccountBalance()*(risk_percent/100.0)/(SL*MarketInfo(Symbol(),MODE_TICKVALUE)*Point/MarketInfo(Symbol(),MODE_TICKSIZE));

   return(MathMin(MathMax(MinLot,MathRound(risk_value/LotStep)*LotStep),MaxLot));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime TimeElapsedSinceLastOpenTrade(string strSymbol,int nMagic)
  {
   datetime timeelapsed=0;
   datetime opentime=0;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))

         if(OrderOpenTime()>opentime) opentime=OrderOpenTime();
     }
   if(opentime==0) return(-1); //fxdaytrader, if there are no open orders yet we can return ...

   timeelapsed=TimeCurrent()-opentime;

// WeekEnd case
//172800 seconds = 48H
//if (DayOfTheWeek(TimeCurrent)=1) and (DayOfTheWeek(OrderOpenTime)>1) then ValeurRetour := ValeurRetour - 48;
   if(BrokerHasSundayCandle==true)
     {
      if((TimeDayOfWeek(TimeCurrent())==0) && (TimeDayOfWeek(opentime)>0)) timeelapsed=timeelapsed-172800;
     }
   else
     {
      if((TimeDayOfWeek(TimeCurrent())==1) && (TimeDayOfWeek(opentime)>1)) timeelapsed=timeelapsed-172800;
     }

// End Of WeekEnd case

   if(timeelapsed<=0) timeelapsed=0;
   return(timeelapsed);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime TimeElapsedSinceLastHistoTrade(string strSymbol,int nMagic)
  {
   datetime timeelapsed=0;
   datetime closetime=0;

   for(int i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))

         if(OrderCloseTime()>closetime) closetime=OrderCloseTime();
     }

   if(closetime==0) return(-1); //fxdaytrader, if there are no orders in history yet, closetime is still==0, so we can return

   timeelapsed=TimeCurrent()-closetime;

// WeekEnd case
//172800 seconds = 48H
//if (DayOfTheWeek(TimeCurrent)=1) and (DayOfTheWeek(OrderOpenTime)>1) then ValeurRetour := ValeurRetour - 48;
   if(BrokerHasSundayCandle==true)
     {
      if((TimeDayOfWeek(TimeCurrent())==0) && (TimeDayOfWeek(closetime)>0)) timeelapsed=timeelapsed-172800;
     }
   else
     {
      if((TimeDayOfWeek(TimeCurrent())==1) && (TimeDayOfWeek(closetime)>1)) timeelapsed=timeelapsed-172800;
     }

// End Of WeekEnd case

   if(timeelapsed<=0) timeelapsed=DeltaTimeHistoTrades+1;
   return(timeelapsed);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountBuys(string strSymbol,int nMagic)
  {
   int nOrderCount=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if(OrderType()==OP_BUY)

         nOrderCount++;
     }
   return(nOrderCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountSells(string strSymbol,int nMagic)
  {
   int nOrderCount=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if(OrderType()==OP_SELL)

         nOrderCount++;
     }
   return(nOrderCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountHisto(string strSymbol,int nMagic)
  {
   int nOrderCount=0;
   for(int i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
         if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))
            if(OrderMagicNumber()==nMagic)
               if(OrderSymbol()==strSymbol)
                  nOrderCount++;
     }
   return(nOrderCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LastOpenTradePrice(string strSymbol,int nMagic)
  {
   double priceLastOpenOrder=0;
   datetime opendate=0;
//for (int i=OrdersTotal()-1 ; i>=0 ; i--)
   for(int i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      //if (!OrderSelect(i,SELECT_BY_POS)) continue;
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;

      if(OrderOpenTime()>=opendate)
        {
         priceLastOpenOrder=OrderOpenPrice();
         opendate=OrderOpenTime();
        }
     }
   return(priceLastOpenOrder);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*double CalculateTpForBuy(string strSymbol)
{  RefreshRates();
	double tp=0;
	 awr_value = 1.385*(iATR(NULL, PERIOD_D1, 14, 1));
	 tp=Ask+NormalizeDouble(awr_value,Digits);
	

	
	return(tp);
}
double CalculateTpForSell(string strSymbol)
{  RefreshRates();

	double tp=0;
	awr_value = 1.385*(iATR(NULL, PERIOD_D1, 14, 1));
	 tp=Bid-NormalizeDouble(awr_value,Digits);


	
	return(tp);
}

*/
bool CheckTradeAllowedMargin()
  {
   bool allowed=true;
   if(IsTesting()==false)
     {
      if((MarketInfo(Symbol(),MODE_MARGINREQUIRED)*lot)>=(AccountFreeMargin()/2))allowed=false;
      if(AccountMargin()>0)
        {
         double freemarginpercentile=(AccountEquity()/AccountMargin())*100;
         if(freemarginpercentile<RequiredMarginPercentile)allowed=false;
        }
     }
   return(allowed);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseFriday(string strSymbol,int nMagic)
  {
   int ticket=-1;
   if((DayOfWeek()==5) && (TimeHour(TimeCurrent())>=21) && FlagCloseFriday==false)
     {
      FlagCloseFriday=true;
      for(int i=OrdersTotal()-1; i>=0; i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS)) continue;
         if(OrderMagicNumber()!=nMagic) continue;
         if(OrderSymbol()!=strSymbol) continue;
         if(OrderType()==OP_BUY)
           {
            ticket=OrderTicket();
            if(OrderProfit()>0)
               if(AllowedSpread(strSymbol)==true)
                  if(OrderOpenPrice()==ReturnLowOpenPrice(strSymbol,MagicNumber,ticket))
                     if(OrderLots()<=0.10)
                       {
                        while(IsTradeContextBusy()) Sleep(100);
                        Alert("CloseFriday:Attempting to close ",strSymbol," of lowest open price");
                        Print("CloseFriday:Attempting to close ",strSymbol," of lowest open price");
                        if(OrderClose(ticket,OrderLots(),Bid,slippage,Red))
                          {
                           Alert("CloseFriday:Close ",strSymbol," Succeeded !");
                           Print("CloseFriday:Close ",strSymbol," Succeeded !");
                          }
                        else
                          {
                           Alert("CloseFriday:Close ",strSymbol," Failed !");
                           Print("CloseFriday:Close ",strSymbol," Failed !");
                          }
                       }
            else
              {
               while(IsTradeContextBusy()) Sleep(100);
               Alert("CloseFriday:Attempting to partial close 0.1 of ",strSymbol," of lowest open price");
               Print("CloseFriday:Attempting to partial close 0.1 of ",strSymbol," of lowest open price");
               if(OrderClose(ticket,0.1,Bid,slippage,Red))
                 {
                  Alert("CloseFriday: Partial close 0.1 of ",strSymbol," Succeeded !");
                  Print("CloseFriday: Partial close 0.1 of ",strSymbol," Succeeded !");
                 }
               else
                 {
                  Alert("CloseFriday: Partial close 0.1 of ",strSymbol," Failed !");
                  Print("CloseFriday: Partial close 0.1 of ",strSymbol," Failed !");
                 }
              }
           }
         if(OrderType()==OP_SELL)
           {
            ticket=OrderTicket();
            if(OrderProfit()>0)
               if(AllowedSpread(strSymbol)==true)
                  if(OrderOpenPrice()==ReturnHighOpenPrice(strSymbol,MagicNumber,ticket))
                     if(OrderLots()<=0.10)
                       {
                        while(IsTradeContextBusy()) Sleep(100);
                        Alert("CloseFriday:Attempting to close ",strSymbol," of highest open price");
                        Print("CloseFriday:Attempting to close ",strSymbol," of highest open price");
                        if(OrderClose(ticket,OrderLots(),Ask,slippage,Red))
                          {
                           Alert("CloseFriday:Close ",strSymbol," Succeeded !");
                           Print("CloseFriday:Close ",strSymbol," Succeeded !");
                          }
                        else
                          {
                           Alert("CloseFriday:Close ",strSymbol," Failed !");
                           Print("CloseFriday:Close ",strSymbol," Failed !");
                          }
                       }
            else
              {
               while(IsTradeContextBusy()) Sleep(100);
               Alert("CloseFriday:Attempting to partial close 0.1 of ",strSymbol," of highest open price");
               Print("CloseFriday:Attempting to partial close 0.1 of ",strSymbol," of highest open price");
               if(OrderClose(ticket,0.1,Ask,slippage,Red))
                 {
                  Alert("CloseFriday:Partial close 0.1 of ",strSymbol," Succeeded !");
                  Print("CloseFriday:Partial close 0.1 of ",strSymbol," Succeeded !");
                 }
               else
                 {
                  Alert("CloseFriday:Partial close 0.1 of ",strSymbol," Failed !");
                  Print("CloseFriday:Partial close 0.1 of ",strSymbol," Failed !");
                 }
              }
           }
        }
     }
   if(DayOfWeek()==1)FlagCloseFriday=false;
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ReturnHighOpenPrice(string strSymbol,int nMagic,int ticket)
  {
   double OrderHighOpenPrice=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))

         if(OrderOpenPrice()>=OrderHighOpenPrice)OrderHighOpenPrice=(OrderOpenPrice()+CostPip*Point);
     }
   if(ticket>0)Order_Select=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   return(OrderHighOpenPrice);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ReturnLowOpenPrice(string strSymbol,int nMagic,int ticket)
  {
   double OrderLowOpenPrice=9999;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))

         if(OrderOpenPrice()<=OrderLowOpenPrice)OrderLowOpenPrice=(OrderOpenPrice()-CostPip*Point);
     }
   if(ticket>0)Order_Select=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);
   return(OrderLowOpenPrice);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetProfitPair(string strSymbol,int nMagic,int ticket)
  {
   double profit=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if((OrderType()==OP_BUY) || (OrderType()==OP_SELL))

         profit=profit+(OrderProfit()+OrderSwap()+OrderCommission());
     }
   if(ticket>0)Order_Select=OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES);//restore pointer for calling func
   return(profit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AllowedSpread(string strSymbol)
  {
   bool IsOk=true;
   if(spread>AdvertisedSpread)IsOk=false;
   return(IsOk);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ManageOpenTrades()
  {
   if(UseCloseFriday==true)CloseFriday(Symbol(),MagicNumber);

   if(UseCSSForTP==true && UseCSS==true) TP_CSS(Symbol(),MagicNumber);

   SetBEAndJump(Symbol(),MagicNumber);
   SetBEAndJumpStackTrade(Symbol(),MagicNumber);

   CloseTheTradeSlope(Symbol(),MagicNumber);
   CloseFirstTwoAgainstUs(Symbol(),MagicNumber);
   

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetBEAndJump(string symbol,int nMagic)
  {

   int ticket=-1;
   double NewSL=0;
   JumpProfit=(adr/2)*BeVarPercent;
   SetBEminPip=(adr)*BeVarPercent;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic)continue;
      if(OrderSymbol()!=symbol)continue;
      if(OrderComment()!="MainTrade")continue;

      if(OrderType()==OP_SELL)
        {
         ticket=OrderTicket();

           {
            if((OrderStopLoss()>OrderOpenPrice() || OrderStopLoss()==0) && ((Ask+(BeVar))<=OrderOpenPrice()))
               NewSL=NormalizeDouble(OrderOpenPrice()-(SecureProfit*Point),Digits);
            else if(NormalizeDouble(OrderStopLoss(),Digits)<=NormalizeDouble(OrderOpenPrice(),Digits))
                                                             NewSL=NormalizeDouble(OrderStopLoss()-(JumpProfit),Digits);

            if((NewSL-Ask)>(SetBEminPip))
              {

               if(((NewSL<OrderStopLoss()) || (OrderStopLoss()<(1*Point))) && (NewSL!=0) && (NewSL>Ask+(10*multiplier*Point)))
                 {

                  Alert("SetBEAndJump :Attempting to move SL of ",symbol," to ",NewSL);
                  Print("SetBEAndJump :Attempting to move SL of ",symbol," to ",NewSL);
                  ModifyOrder(ticket,NewSL,0);
                  if(PartCloseWithMovingSLMain==true)
                    {
                     PartCloseTrade(ticket);
                     Alert(PartClosePercent,"% of Position closed");
                    }
                 }
              }
           }

         return;

        }

      if(OrderType()==OP_BUY)
        {
         ticket=OrderTicket();

           {

            if((OrderStopLoss()<OrderOpenPrice() || OrderStopLoss()==0) && ((Bid-(BeVar))>=OrderOpenPrice()))
               NewSL=NormalizeDouble(OrderOpenPrice()+(SecureProfit*Point),Digits);
            else if(NormalizeDouble(OrderStopLoss(),Digits)>=NormalizeDouble(OrderOpenPrice(),Digits))
                                                             NewSL=NormalizeDouble(OrderStopLoss()+(JumpProfit),Digits);
            if((Bid-NewSL)>(SetBEminPip))
              {
               if(((NewSL>OrderStopLoss()) || (OrderStopLoss()<(1*Point))) && (NewSL!=0) && (NewSL<Bid -(10*multiplier*Point)))
                 {

                  Alert("SetBEAndJump :Attempting to move SL of ",symbol," to ",NewSL);
                  Print("SetBEAndJump :Attempting to move SL of ",symbol," to ",NewSL);
                  ModifyOrder(ticket,NewSL,0);
                  if(PartCloseWithMovingSLMain==true)
                    {
                     PartCloseTrade(ticket);
                     Alert(PartClosePercent,"% of Position closed");
                    }
                 }
              }
           }

        }

     }
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetBEAndJumpStackTrade(string symbol,int nMagic)
  {

   int ticket=-1;
   double NewSL=0;
   JumpProfitST=(adr/2)*BeVarPercent;
   SetBEminPipST=(adr)*BeVarPercent;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic)continue;
      if(OrderSymbol()!=symbol)continue;
      if(OrderComment()!="StackTrade")continue;
      if(OrderType()==OP_SELL)
        {
         ticket=OrderTicket();

           {
            if((OrderStopLoss()>OrderOpenPrice() || OrderStopLoss()==0) && ((Ask+(BeVar))<=OrderOpenPrice()))
               NewSL=NormalizeDouble(OrderOpenPrice()-(SecureProfitST*Point),Digits);
            else if(NormalizeDouble(OrderStopLoss(),Digits)<=NormalizeDouble(OrderOpenPrice(),Digits))
                                                             NewSL=NormalizeDouble(OrderStopLoss()-(JumpProfitST),Digits);

            if((NewSL-Bid)>(SetBEminPipST))
              {

               if(((NewSL<OrderStopLoss()) || (OrderStopLoss()<(1*Point))) && (NewSL!=0) && (NewSL>Ask+(10*multiplier*Point)))
                 {

                  Alert("SetBEAndJumpStackTrade :Attempting to move SL of ",symbol," to ",NewSL);
                  Print("SetBEAndJumpStackTrade :Attempting to move SL of ",symbol," to ",NewSL);
                  ModifyOrder(ticket,NewSL,0);
                  if(PartCloseWithMovingSLStack==true)
                    {
                     PartCloseTrade(ticket);
                     Alert(PartClosePercent,"% of Position closed");
                    }
                 }
              }
           }

        }

      if(OrderType()==OP_BUY)
        {
         ticket=OrderTicket();

           {

            if((OrderStopLoss()<OrderOpenPrice() || OrderStopLoss()==0) && ((Bid-(BeVar))>=OrderOpenPrice()))
               NewSL=NormalizeDouble(OrderOpenPrice()+(SecureProfitST*Point),Digits);
            else if(NormalizeDouble(OrderStopLoss(),Digits)>=NormalizeDouble(OrderOpenPrice(),Digits))
                                                             NewSL=NormalizeDouble(OrderStopLoss()+(JumpProfitST),Digits);
            if((Bid-NewSL)>(SetBEminPipST))
              {
               if(((NewSL>OrderStopLoss()) || (OrderStopLoss()<(1*Point))) && (NewSL!=0) && (NewSL<Bid -(10*multiplier*Point)))
                 {

                  Alert("SetBEAndJumpStackTrade :Attempting to move SL of ",symbol," to ",NewSL);
                  Print("SetBEAndJumpStackTrade :Attempting to move SL of ",symbol," to ",NewSL);
                  ModifyOrder(ticket,NewSL,0);
                  if(PartCloseWithMovingSLStack==true)
                    {
                     PartCloseTrade(ticket);
                     Alert(PartClosePercent,"% of Position closed");
                    }
                 }
              }
           }

        }

     }
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TP_CSS(string strSymbol,int nMagic)

  {
   int ticket=-1;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS)) continue;
      if(OrderMagicNumber()!=nMagic) continue;
      if(OrderSymbol()!=strSymbol) continue;
      if(OrderType()==OP_SELL)
        {
         ticket=OrderTicket();
         if(GetProfitPair(strSymbol,nMagic,ticket)>MinTPProfitInUSD)
            // if(TimeElapsedSinceLastHistoBuy(strSymbol, MagicNumber,OrderTicket())>=DeltaTimeLiveTrades)
            if(CurrVal1[1]>CurrVal2[1] && CurrVal1[2]>CurrVal2[2] && CurrVal1[3]>CurrVal2[3])

               if(AllowedSpread(strSymbol)==true)
                  if(OrderLots()<=0.10)
                    {
                     while(IsTradeContextBusy()) Sleep(100);
                     Alert("CloseOnTP_CSS :Attempting to close ",strSymbol);
                     Print("CloseOnTP_CSS :Attempting to close ",strSymbol);
                     if(OrderClose(ticket,OrderLots(),Ask,slippage,Red))
                       {
                        Alert("CloseOnTP_CSS :Close ",strSymbol," Succeeded ! ");
                        Print("CloseOnTP_CSS :Close ",strSymbol," Succeeded ! ");
                       }
                     else
                       {
                        Alert("CloseOnTP_CSS :Close ",strSymbol," Failed ! ");
                        Print("CloseOnTP_CSS :Close ",strSymbol," Failed ! ");
                       }
                    }
         else
           {
            while(IsTradeContextBusy()) Sleep(100);
            Alert("CloseOnTP_CSS :Attempting to partially close ",strSymbol);
            Print("CloseOnTP_CSS :Attempting to partially close ",strSymbol);
            if(OrderClose(ticket,0.1,Ask,slippage,Red))
              {
               Alert("CloseOnTP_CSS : Partial Close ",strSymbol," Succeeded ! ");
               Print("CloseOnTP_CSS : Partial Close ",strSymbol," Succeeded ! ");
              }
            else
              {
               Alert("CloseOnTP_CSS : Partial Close ",strSymbol," Failed ! ");
               Print("CloseOnTP_CSS : Partial Close ",strSymbol," Failed ! ");
              }
           }

        }

      if(OrderType()==OP_BUY)
        {
         ticket=OrderTicket();

         if(CurrVal2[1]>CurrVal1[1] && CurrVal2[2]>CurrVal1[2] && CurrVal2[3]>CurrVal1[3])
            if(GetProfitPair(strSymbol,nMagic,ticket)>MinTPProfitInUSD)
               //if(TimeElapsedSinceLastHistoBuy(strSymbol, MagicNumber,OrderTicket())>=DeltaTimeLiveTrades)
               if(AllowedSpread(strSymbol)==true)
                  if(OrderLots()<=0.10)
                    {
                     while(IsTradeContextBusy()) Sleep(100);
                     Alert("CloseOnTP_CSS :Attempting to close ",strSymbol);
                     Print("CloseOnTP_CSS :Attempting to close ",strSymbol);
                     if(OrderClose(ticket,OrderLots(),Ask,slippage,Red))
                       {
                        Alert("CloseOnTP_CSS :Close ",strSymbol," Succeeded ! ");
                        Print("CloseOnTP_CSS :Close ",strSymbol," Succeeded ! ");
                       }
                     else
                       {
                        Alert("CloseOnTP_CSS :Close ",strSymbol," Failed ! ");
                        Print("CloseOnTP_CSS :Close ",strSymbol," Failed ! ");
                       }
                    }
         else
           {
            while(IsTradeContextBusy()) Sleep(100);
            Alert("CloseOnTP_CSS :Attempting to partially close ",strSymbol);
            Print("CloseOnTP_CSS :Attempting to partially close ",strSymbol);
            if(OrderClose(ticket,0.1,Ask,slippage,Red))
              {
               Alert("CloseOnTP_CSS : Partial Close ",strSymbol," Succeeded ! ");
               Print("CloseOnTP_CSS : Partial Close ",strSymbol," Succeeded ! ");
              }
            else
              {
               Alert("CloseOnTP_CSS : Partial Close ",strSymbol," Failed ! ");
               Print("CloseOnTP_CSS : Partial Close ",strSymbol," Failed ! ");
              }
           }

        }

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseTheTradeSlope(string strSymbol,int nMagic)
  {
   int shift;//For the iBarShift to get the candle shift of the trading candle
   static datetime OldTime=0;//Only need the test at the start of each candle
   if(OldTime!=Time[0])
     {
      ReadIndicators();

      OldTime=Time[0];

      int ticket=-1;

      for(int i=OrdersTotal()-1; i>=0; i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS)) continue;
         if(OrderMagicNumber()!=nMagic) continue;
         if(OrderSymbol()!=strSymbol) continue;

         if(OrderType()==OP_SELL)
           {
            ticket=OrderTicket();

            shift=iBarShift(NULL,PERIOD_SR,OrderOpenTime(),false);
            if((shift==5 && HtfSlopeVal[0]>-0.4))
              {

               if(AllowedSpread(strSymbol)==true)
                 {
                  Alert("CloseTheTrade :Attempting to close ",strSymbol);
                  Print("CloseTheTrade :Attempting to close ",strSymbol);
                  if(OrderClose(ticket,OrderLots(),Ask,slippage,Red))
                    {
                     Alert("CloseTheTrade :Close ",strSymbol," Succeeded !");
                     Print("CloseTheTrade :Close ",strSymbol," Succeeded !");
                    }
                  else
                    {
                     Alert("CloseTheTrade :Close ",strSymbol," Failed !");
                     Print("CloseTheTrade :Close ",strSymbol," Failed !");
                    }
                 }

              }

           }
         if(OrderType()==OP_BUY)

           {
            ticket=OrderTicket();

            shift=iBarShift(NULL,PERIOD_SR,OrderOpenTime(),false);
            if((shift==5 && HtfSlopeVal[0]<0.4))
              {

               if(AllowedSpread(strSymbol)==true)
                 {
                  Alert("CloseTheTrade :Attempting to close ",strSymbol);
                  Print("CloseTheTrade :Attempting to close ",strSymbol);
                  if(OrderClose(ticket,OrderLots(),Bid,slippage,Red))
                    {
                     Alert("CloseTheTrade :Close ",strSymbol," Succeeded !");
                     Print("CloseTheTrade :Close ",strSymbol," Succeeded !");
                    }
                  else
                    {
                     Alert("CloseTheTrade :Close ",strSymbol," Failed !");
                     Print("CloseTheTrade :Close ",strSymbol," Failed !");

                    }
                 }

              }
           }
        }
     }
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseFirstTwoAgainstUs(string strSymbol,int nMagic)
  {
   int shift;//For the iBarShift to get the candle shift of the trading candle
   static datetime OldTime=0;//Only need the test at the start of each candle
   if(OldTime!=Time[0])
     {
      ReadIndicators();

      OldTime=Time[0];

      int ticket=-1;

      for(int i=OrdersTotal()-1; i>=0; i--)
        {
         if(!OrderSelect(i,SELECT_BY_POS)) continue;
         if(OrderMagicNumber()!=nMagic) continue;
         if(OrderSymbol()!=strSymbol) continue;

         if(OrderType()==OP_SELL)
           {
            ticket=OrderTicket();

            shift=iBarShift(NULL,PERIOD_2CandleRule,OrderOpenTime(),false);
            if(shift==2)
              {
               if(iClose(NULL,PERIOD_2CandleRule,shift)>iOpen(NULL,PERIOD_2CandleRule,shift))
                 {
                  if(iClose(NULL,PERIOD_2CandleRule,shift-1)>iOpen(NULL,PERIOD_2CandleRule,shift-1))
                    {

                     if(AllowedSpread(strSymbol)==true)
                       {
                        Alert("CloseTheTrade :Attempting to close ",strSymbol);
                        Print("CloseTheTrade :Attempting to close ",strSymbol);
                        if(OrderClose(ticket,OrderLots(),Ask,slippage,Red))
                          {
                           Alert("CloseTheTrade :Close ",strSymbol," Succeeded !");
                           Print("CloseTheTrade :Close ",strSymbol," Succeeded !");
                          }
                        else
                          {
                           Alert("CloseTheTrade :Close ",strSymbol," Failed !");
                           Print("CloseTheTrade :Close ",strSymbol," Failed !");
                          }
                       }

                    }
                 }

              }

           }
         if(OrderType()==OP_BUY)

           {
            ticket=OrderTicket();
            shift=iBarShift(NULL,PERIOD_2CandleRule,OrderOpenTime(),false);
            if(shift==2)
              {
               if(iClose(NULL,PERIOD_2CandleRule,shift)<iOpen(NULL,PERIOD_2CandleRule,shift))
                 {
                  if(iClose(NULL,PERIOD_2CandleRule,shift-1)<iOpen(NULL,PERIOD_2CandleRule,shift-1))
                    {

                     if(AllowedSpread(strSymbol)==true)
                       {
                        Alert("CloseTheTrade :Attempting to close ",strSymbol);
                        Print("CloseTheTrade :Attempting to close ",strSymbol);
                        if(OrderClose(ticket,OrderLots(),Bid,slippage,Red))
                          {
                           Alert("CloseTheTrade :Close ",strSymbol," Succeeded !");
                           Print("CloseTheTrade :Close ",strSymbol," Succeeded !");
                          }
                        else
                          {
                           Alert("CloseTheTrade :Close ",strSymbol," Failed !");
                           Print("CloseTheTrade :Close ",strSymbol," Failed !");

                          }
                       }
                    }
                 }
              }
           }
        }
     }
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReadIndicators()
  {

   int m_bar=0;//Need to deal with a Sunday candle
   int d=TimeDayOfWeek(TimeCurrent());
   if(d==1 && BrokerHasSundayCandle && Period()==1440) m_bar=m_bar+1;

   adr=GetAtr(Symbol(),PERIOD_ATR,5,m_bar+1);
if(UseCSS==true)
     {

   SplitSymbol();//Split the Symbol into its constituent currencies. Also finds their index for passing to CSS
   CurrVal1[1] = GetCSS(CurrIndex1,m_bar);
   CurrVal2[1] = GetCSS(CurrIndex2,m_bar);



   CurrVal1[2] = GetCSS(CurrIndex1,m_bar+ 1);
   CurrVal2[2] = GetCSS(CurrIndex2,m_bar+1);


   CurrVal1[3] = GetCSS(CurrIndex1,m_bar+ 2);
   CurrVal2[3] = GetCSS(CurrIndex2,m_bar+ 2);
   }
//slope

   if(HtfTimeFrame>0)
     {
      HtfSlopeVal[0]= GetSlope(Symbol(),HtfTimeFrame,m_bar);
      HtfSlopeTrend = ranging;
      if(HtfSlopeVal[0] >= HtfBuyOnlyLevel) HtfSlopeTrend = buyonly;
      if(HtfSlopeVal[0] >= HtfBuyHoldLevel) HtfSlopeTrend = buyhold;
      if(HtfSlopeVal[0] <= HtfSellOnlyLevel) HtfSlopeTrend = sellonly;
      if(HtfSlopeVal[0] <= HtfSellHoldLevel) HtfSlopeTrend = sellhold;


      HtfSlopeVal[1]=GetSlope(Symbol(),HtfTimeFrame,m_bar+1);

      HtfSlopeAngle=unchanged;
      if(HtfSlopeVal[0] > HtfSlopeVal[1]) HtfSlopeAngle = rising;
      if(HtfSlopeVal[0] < HtfSlopeVal[1]) HtfSlopeAngle = falling;
     }//IF (HtfTimeFrame > 0)


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LookForTrading()
  {

   ReadIndicators();

   SignalBuy=false;
   SignalSell=false;
   SignalBuyStack=false;
   SignalSellStack=false;
   int res_zone_strenght=0; 
   int sup_zone_strenght=0;
   int res_zone_hits=0; 
   int sup_zone_hits=0; 
   double res_zone_hi=0;
   double res_zone_lo=0;
   double sup_zone_hi=0;
   double sup_zone_lo=0;
   
   
   BuyOk=0;
   SellOk=0;
  res_zone = SSSR_FindZoneV2(SSSR_UP, true, Bid, res_hi, res_lo, res_strength);
   sup_zone = SSSR_FindZoneV2(SSSR_DN, true, Bid, sup_hi, sup_lo, sup_strength);
  res_zone_hits=SSSR_GetZoneHits(res_zone);
  sup_zone_hits=SSSR_GetZoneHits(sup_zone);
  res_zone_hi=SSSR_GetZoneHi(res_zone);
  res_zone_lo=SSSR_GetZoneLo(res_zone);
  sup_zone_hi=SSSR_GetZoneHi(sup_zone);
  sup_zone_lo=SSSR_GetZoneLo(sup_zone);
  
   if(UseCSS==true)
     {

      // need to reset CSS Values to yes
      CSS_Allowed_Sell=1;
      CSS_Allowed_Buy=1;

      //Define direction
      //Currency 1
      if(CurrVal1[1]>0 && CurrVal1[1]>=CurrVal1[2]) CurrDirection1=upaccelerating;
      if(CurrVal1[1]>0 && CurrVal1[1]<CurrVal1[2]) CurrDirection1=updecelerating;

      if(CurrVal1[1]<0 && CurrVal1[1]<=CurrVal1[2]) CurrDirection1=downaccelerating;
      if(CurrVal1[1]<0 && CurrVal1[1]>CurrVal1[2]) CurrDirection1=downdecelerating;

      //Currency 2
      if(CurrVal2[1]>0 && CurrVal2[1]>=CurrVal2[2]) CurrDirection2=upaccelerating;
      if(CurrVal2[1]>0 && CurrVal2[1]<CurrVal2[2]) CurrDirection2=updecelerating;

      if(CurrVal2[1]<0 && CurrVal2[1]<=CurrVal2[2]) CurrDirection2=downaccelerating;
      if(CurrVal2[1]<0 && CurrVal2[1]>CurrVal2[2]) CurrDirection2=downdecelerating;
      //Set CSS to no if we have no CSS trading conditions
      //Set CSS to no if we have no CSS trading conditions
      if(UseCSSForEntry==true)
        {
         if(CurrDirection1==upaccelerating || CurrDirection1==updecelerating) CSS_Allowed_Sell=0;

         if(CurrDirection2==downaccelerating || CurrDirection2==downdecelerating) CSS_Allowed_Sell=0;

         if(CurrDirection1== downaccelerating|| CurrDirection1== downdecelerating)CSS_Allowed_Buy=0;
         if(CurrDirection2== upaccelerating|| CurrDirection2 == updecelerating) CSS_Allowed_Buy=0;
        }


     }//if (UseCSS)

// SIGNAL BUY CHECK

   if(CountSells(Symbol(),MagicNumber)==0 && CountBuys(Symbol(),MagicNumber)==0)
     {



       if ((Bid<=NormalizeDouble(sup_zone_lo,Digits)) &&  (MathAbs(sup_zone_lo-Bid)<=(BufferPipsOpen*Point))&& sup_zone_hits>=MinHitsForUsingZone)
       {
       BuyOk=1;
       SR_TP=NormalizeDouble(sup_zone_hi,Digits);
               if(SR_TP<Ask+(BufferPips*Point)) SR_TP=Ask+(BufferPips*Point);
       }


      

      if((BuyOk==1))

         if(TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)>DeltaTimeLiveTrades || TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)==-1)
            if(TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)>DeltaTimeHistoTrades || TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)==-1)

               if(CSS_Allowed_Buy==1)
                 {

                  SignalBuy=true;

                 }
 
     }
   if(AddAdditionalPositionsInTrend==true && TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)>=DeltaTimeLiveTrades)

      if(CountSells(Symbol(),MagicNumber)==0 && (CountBuys(Symbol(),MagicNumber)>0 && CountBuys(Symbol(),MagicNumber)<=MaxAdditionalPositions))
        {

       if ((Bid<=NormalizeDouble(sup_zone_lo,Digits)) &&  (MathAbs(sup_zone_lo-Bid)<=(BufferPipsOpen*Point))&& sup_zone_hits>=MinHitsForUsingZone)
      {
       BuyOk=1;
       SR_TP=NormalizeDouble(sup_zone_hi,Digits);
               if(SR_TP<Ask+(BufferPips*Point)) SR_TP=Ask+(BufferPips*Point);
       }

         if((BuyOk==1))
            if(TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)>DeltaTimeLiveTrades || TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)==-1)
               if(TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)>DeltaTimeHistoTrades || TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)==-1)

                  if(CSS_Allowed_Buy==1)
                    {

                     SignalBuyStack=true;

                    }

        }//if (AddAdditionalPositionsInTrend==true &&

// SIGNAL SELL CHECK

   if(CountSells(Symbol(),MagicNumber)==0 && CountBuys(Symbol(),MagicNumber)==0)

     {

      
       if ((Bid>=NormalizeDouble(res_zone_hi,Digits)) &&  (MathAbs(Bid-res_zone_hi)<=(BufferPipsOpen*Point)) && res_zone_hits>=MinHitsForUsingZone)
        {
       SR_TP=res_zone_lo;
               if(SR_TP>Bid-(BufferPips*Point)) SR_TP=Bid-(BufferPips*Point);
       SellOk=1;
       }

      if((SellOk==1))

         if(TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)>DeltaTimeLiveTrades || TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)==-1)
            if(TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)>DeltaTimeHistoTrades || TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)==-1)

               if(CSS_Allowed_Sell==1)

                 {

                  SignalSell=true;

                 }

     }
   if(AddAdditionalPositionsInTrend==true && TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)>=DeltaTimeLiveTrades)

      if(CountSells(Symbol(),MagicNumber)>0 && (CountBuys(Symbol(),MagicNumber)==0 && CountSells(Symbol(),MagicNumber)<=MaxAdditionalPositions))
        {

        
       if ((Bid>=NormalizeDouble(res_zone_hi,Digits)) &&  (MathAbs(Bid-res_zone_hi)<=(BufferPipsOpen*Point))&& res_zone_hits>=MinHitsForUsingZone)
       {
       SR_TP=res_zone_lo;
               if(SR_TP>Bid-(BufferPips*Point)) SR_TP=Bid-(BufferPips*Point);
       SellOk=1;
       }

         if((SellOk==1))
            if(TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)>DeltaTimeLiveTrades || TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)==-1)
               if(TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)>DeltaTimeHistoTrades || TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)==-1)

                  if(CSS_Allowed_Sell==1)
                    {

                     SignalSellStack=true;

                    }

        }//if (AddAdditionalPositionsInTrend==true &&

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAtr(string symbol,int tf,int period,int shift)
  {
//Returns the value of atr

   return(iATR(symbol, tf, period, shift) );

  }//End double GetAtr()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SplitSymbol()
  {
   Curr1 = StringSubstrOld(Symbol(), 0, 3);
   Curr2 = StringSubstrOld(Symbol(), 3, 3);

//Calculate the index to pass to CSS
   int cc;
   for(cc=0; cc<ArraySize(CurrNames); cc++)
     {
      if(Curr1==CurrNames[cc])
        {
         CurrIndex1=cc;
         break;
        }//if (Curr1 == CurrNames[cc])
     }//for (cc = 0; cc < ArraySize(CurrNames); cc++)

   for(cc=0; cc<ArraySize(CurrNames); cc++)
     {
      if(Curr2==CurrNames[cc])
        {
         CurrIndex2=cc;
         break;
        }//if (Curr1 == CurrNames[cc])
     }//for (cc = 0; cc < ArraySize(CurrNames); cc++)

  }//End void SplitSymbol()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetCSS(double index,int shift)
  {

// Initialize
   double myCSS[];
// Call libary
// Do not care about multiple calls, libCCS caches its values internally
   libCSSgetCSS(myCSS,CssTf,shift,true);

   int currencyIndex=NormalizeDouble(index,0);

   return ( myCSS[currencyIndex] );

  }//End double GetCSS(int index, int shift)
/////////////////////////////////////////////////////////////////////////////////////////
// steve stuff   ////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
void SM(string message)
  {

   ScreenMessage=StringConcatenate(ScreenMessage,Gap,message);

  }//End void SM()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayUserFeedback()
  {
   if(IsTesting()==true && IsVisualMode()==false) return;

   ScreenMessage="";
   string zone_strength_r="";
    string zone_strength_s="";
   if (res_strength==0) zone_strength_r="weak";
   if (res_strength==1) zone_strength_r="turncoat";
   if (res_strength==2) zone_strength_r="unproven";
   if (res_strength==3) zone_strength_r="verified";
   if (res_strength==4) zone_strength_r="proven";
   if (sup_strength==0) zone_strength_s="weak";
   if (sup_strength==1) zone_strength_s="turncoat";
   if (sup_strength==2) zone_strength_s="unproven";
   if (sup_strength==3) zone_strength_s="verified";
   if (sup_strength==4) zone_strength_s="proven";
  
  
  
//ScreenMessage = StringConcatenate(ScreenMessage,Gap + NL);
   SM(NL);

   SM("Updates for this EA are to be found at http://www.stevehopwoodforex.com/phpBB3/viewtopic.php?f=5&t=3343"+NL);
   SM("Feeling generous? Help keep SHF going with a small Paypal donation to pianodoodler@gmail.com"+NL);
   SM("Broker time = "+TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+": Local time = "+TimeToStr(TimeLocal(),TIME_DATE|TIME_SECONDS)+NL);
   SM(version+NL);
   if(UseCSS)
     {
      SM("CSS Values: "+Curr1+" actual = "+DoubleToStr(CurrVal1[1],4)+" last closed candle = "+DoubleToStr(CurrVal1[2],4)+": Direction is "+CurrDirection1+NL);
      SM("CSS Values: "+Curr2+" actual = "+DoubleToStr(CurrVal2[1],4)+" last closed  candle= "+DoubleToStr(CurrVal2[2],4)+": Direction is "+CurrDirection2+NL);
      if(UseCSSForEntry==true)
        {
         SM("Allowed Buy CSS(1=ok)= "+CSS_Allowed_Buy+NL);
         SM("Allowed Sell CSS(1=ok)= "+CSS_Allowed_Sell+NL);
        }
     }//if (UseCSS)
     // get details of the zones and print them to the screen
   if (res_zone >= 0)
      SM("Next Resistance Zone High: "+DoubleToStr(res_hi, Digits)+" Next Resistance Zone Low:"+DoubleToStr(res_lo,Digits)+" "+" Zone Strenth: "+zone_strength_r+NL);
   else
     SM( "No Resistance Found, "+NL);

   if (sup_zone >= 0)
      SM( "Next Support Zone High: "+DoubleToStr(sup_hi, Digits)+" Next Support Zone Low:"+DoubleToStr(sup_lo,Digits)+" "+" Zone Strenth: "+zone_strength_s+NL);
   else
      SM( "No Support Found."+NL);
   SM("TimeElaspsedSinceLastOpenTrade="+TimeElapsedSinceLastOpenTrade(Symbol(),MagicNumber)+" seconds"+NL);
   SM("TimeElapsedSinceLastClosed Histo Trade="+TimeElapsedSinceLastHistoTrade(Symbol(),MagicNumber)+" seconds"+NL);

   SM("Open Price of last open order="+DoubleToStr(LastOpenTradePrice(Symbol(),MagicNumber),Digits)+NL);

   SM("Echo Symbol="+Symbol()+NL);
   SM("Digits="+Digits+NL);
   SM("Multiplier="+multiplier+NL);



   if(HtfTimeFrame>0)
     {
      SM("TMA-Slope value actual "+DoubleToStr(HtfSlopeVal[0],4)+": Trend is "+HtfSlopeTrend+HtfSlopeAngle+NL);
      SM("TMA-Slope value last candle "+DoubleToStr(HtfSlopeVal[1],4)+NL);
      //SM("Htf value " + DoubleToStr(HtfSlopeVal, 4) + ": Trend is " + HtfSlopeTrend + HtfSlopeAngle + NL);                                                                
     }//if (HtfTimeFrame > 0)


   SM("SignalBuy="+SignalBuy+NL);
   SM("SignalSell="+SignalSell+NL);
   SM("Count Active Buys="+CountBuys(Symbol(),MagicNumber)+NL);
   SM("Count Active Sells="+CountSells(Symbol(),MagicNumber)+NL);
   SM("Count Historical Trades="+CountHisto(Symbol(),MagicNumber)+NL);
   SM("Trade Allowed Margin="+CheckTradeAllowedMargin()+NL);
   SM("Allowed Spread is = "+DoubleToStr((AdvertisedSpread*0.1),1)+" Actual Spread is= "+DoubleToStr((spread*0.1),1)+NL);
   

   
   Comment(ScreenMessage);

  }//void DisplayUserFeedback()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SendSingleTrade(string symbol,int type,string comment,double lotsize,double price,double stop,double take)
  {
//pah (Paul) contributed the code to get around the trade context busy error. Many thanks, Paul.

   lotsize=NormalizeLots(symbol,lotsize); //fxdaytrader, normalize lots

   color col=Red;
   if(type==OP_BUY || type==OP_BUYSTOP) col=Green;

   int expiry=0;
//if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);

//RetryCount is declared as 10 in the Trading variables section at the top of this file
   for(int cc=0; cc<RetryCount; cc++)
     {
      //for (int d = 0; (d < RetryCount) && IsTradeContextBusy(); d++) Sleep(100);

      RefreshRates();
      if(type == OP_BUY) price = MarketInfo(symbol, MODE_ASK);
      if(type == OP_SELL) price = MarketInfo(symbol, MODE_BID);

      while(IsTradeContextBusy()) Sleep(100);//Put here so that excess slippage will cancel the trade if the ea has to wait for some time.

      if(!BrokerIsECN) int ticket=OrderSend(symbol,type,lotsize,price,slippage,stop,take,comment,MagicNumber,expiry,col);

      //Is a 2 stage Broker
      if(BrokerIsECN)
        {
         ticket=OrderSend(symbol,type,lotsize,price,slippage,0,0,comment,MagicNumber,expiry,col);
         if(ticket>-1)
           {
            ModifyOrder(ticket,stop,take);
           }//if (ticket > 0)}
        }//if (BrokerIsECN)

      if(ticket>-1) break;//Exit the trade send loop
      if(cc == RetryCount - 1) return(false);

      //Error trapping for both
      if(ticket<0)
        {
         string stype;
         if(type == OP_BUY) stype = "OP_BUY";
         if(type == OP_SELL) stype = "OP_SELL";
         if(type == OP_BUYLIMIT) stype = "OP_BUYLIMIT";
         if(type == OP_SELLLIMIT) stype = "OP_SELLLIMIT";
         if(type == OP_BUYSTOP) stype = "OP_BUYSTOP";
         if(type == OP_SELLSTOP) stype = "OP_SELLSTOP";
         int err=GetLastError();
         Alert(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         Print(symbol," ",WindowExpertName()," ",stype," order send failed with error(",err,"): ",ErrorDescription(err));
         return(false);
        }//if (ticket < 0)  
     }//for (int cc = 0; cc < RetryCount; cc++);

   TicketNo=ticket;
//Make sure the trade has appeared in the platform's history to avoid duplicate trades.
//My mod of Matt's code attempts to overcome the bastard crim's attempts to overcome Matt's code.
   bool TradeReturnedFromBroker=false;
   while(!TradeReturnedFromBroker)
     {
      TradeReturnedFromBroker=O_R_CheckForHistory(ticket);
      if(!TradeReturnedFromBroker)
        {
         Alert(Symbol()," sent trade not in your trade history yet. Turn of this ea NOW.");
        }//if (!TradeReturnedFromBroker)
     }//while (!TradeReturnedFromBroker)

//Got this far, so trade send succeeded
   return(true);

  }//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyOrder(int ticket,double stop,double take)
  {
//Modifies an order already sent if the crim is ECN.

   if(stop==0 && take==0) return; //nothing to do

   if(!OrderSelect(ticket,SELECT_BY_TICKET)) return;//Trade does not exist, so no mod needed

                                                    //RetryCount is declared as 10 in the Trading variables section at the top of this file   
   for(int cc=0; cc<RetryCount; cc++)
     {
      for(int d=0;(d<RetryCount) && IsTradeContextBusy(); d++) Sleep(100);
      if(take>0 && stop>0)
        {
         while(IsTradeContextBusy()) Sleep(100);
         if(OrderModify(ticket,OrderOpenPrice(),stop,take,OrderExpiration(),CLR_NONE))
           {
            Alert("Modify Order Succeeded !");
            Print("Modify Order Succeeded !");
            return;
           }
        }//if (take > 0 && stop > 0)

      if(take!=0 && stop==0)
        {
         while(IsTradeContextBusy()) Sleep(100);
         if(OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),take,OrderExpiration(),CLR_NONE))
           {
            Alert("Modify Order Succeeded !");
            Print("Modify Order Succeeded !");
            return;
           }
        }//if (take == 0 && stop != 0)

      if(take==0 && stop!=0)
        {
         while(IsTradeContextBusy()) Sleep(100);
         if(OrderModify(ticket,OrderOpenPrice(),stop,OrderTakeProfit(),OrderExpiration(),CLR_NONE))
           {
            Alert("Modify Order Succeeded !");
            Print("Modify Order Succeeded !");
            return;
           }
        }//if (take == 0 && stop != 0)
     }//for (int cc = 0; cc < RetryCount; cc++)

//Got this far, so the order modify failed
   int err=GetLastError();
   Print(Symbol()," SL/TP  order modify failed with error(",err,"): ",ErrorDescription(err));
   Alert(Symbol()," SL/TP  order modify failed with error(",err,"): ",ErrorDescription(err));

  }//void ModifyOrder(int ticket, double tp, double sl)
//=============================================================================
//                           O_R_CheckForHistory()
//
//  This function is to work around a very annoying and dangerous bug in MT4:
//      immediately after you send a trade, the trade may NOT show up in the
//      order history, even though it exists according to ticket number.
//      As a result, EA's which count history to check for trade entries
//      may give many multiple entries, possibly blowing your account!
//
//  This function will take a ticket number and loop until
//  it is seen in the history.
//
//  RETURN VALUE:
//     TRUE if successful, FALSE otherwise
//
//
//  FEATURES:
//     * Re-trying under some error conditions, sleeping a random
//       time defined by an exponential probability distribution.
//
//     * Displays various error messages on the log for debugging.
//
//  ORIGINAL AUTHOR AND DATE:
//     Matt Kennel, 2010
//
//=============================================================================
bool O_R_CheckForHistory(int ticket)
  {
//My thanks to Matt for this code. He also has the undying gratitude of all users of my trading robots

   int lastTicket=OrderTicket();

   int cnt=0;
   int err=GetLastError(); // so we clear the global variable.
   err=0;
   bool exit_loop=false;
   bool success=false;

   while(!exit_loop)
     {
/* loop through open trades */
      int total=OrdersTotal();
      for(int c=0; c<total; c++)
        {
         if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if(OrderTicket()==ticket)
              {
               success=true;
               exit_loop=true;
              }
           }
        }
      if(cnt>3)
        {
/* look through history too, as order may have opened and closed immediately */
         total=OrdersHistoryTotal();
         for(c=0; c<total; c++)
           {
            if(OrderSelect(c,SELECT_BY_POS,MODE_HISTORY)==true)
              {
               if(OrderTicket()==ticket)
                 {
                  success=true;
                  exit_loop=true;
                 }
              }
           }
        }

      cnt=cnt+1;
      if(cnt>O_R_Setting_max_retries)
        {
         exit_loop=true;
        }
      if(!(success || exit_loop))
        {
         Print("Did not find #"+ticket+" in history, sleeping, then doing retry #"+cnt);
         O_R_Sleep(O_R_Setting_sleep_time,O_R_Setting_sleep_max);
        }
     }
// Select back the prior ticket num in case caller was using it.
   if(lastTicket>=0)
     {
      Order_Select=OrderSelect(lastTicket,SELECT_BY_TICKET,MODE_TRADES);
     }
   if(!success)
     {
      Print("Never found #"+ticket+" in history! crap!");
     }
   return(success);
  }//End bool O_R_CheckForHistory(int ticket)
//=============================================================================
//                              O_R_Sleep()
//
//  This sleeps a random amount of time defined by an exponential
//  probability distribution. The mean time, in Seconds is given
//  in 'mean_time'.
//  This returns immediately if we are backtesting
//  and does not sleep.
//
//=============================================================================
void O_R_Sleep(double mean_time,double max_time)
  {
   if(IsTesting())
     {
      return;   // return immediately if backtesting.
     }
   double p = (MathRand()+1) / 32768.0;
   double t = -MathLog(p)*mean_time;
   t=MathMin(t,max_time);
   int ms=t*1000;
   if(ms<10)
     {
      ms=10;
     }
   Sleep(ms);
  }//End void O_R_Sleep(double mean_time, double max_time)

//+------------------------------------------------------------------+
//|                                                       LibCSS.mq4 |
//|                      Copyright 2013, Deltabron - Paul Geirnaerdt |
//|                                          http://www.deltabron.nl |
//+------------------------------------------------------------------+

#define libCSSversion            "v1.1.2"
#define libCSSEPSILON            0.00000001
#define libCSSCURRENCYCOUNT      8

//+------------------------------------------------------------------+
//| Release Notes                                                    |
//+------------------------------------------------------------------+
// v1.0.0, 5/7/13
// * Initial release
// * NanningBob's 10.5 rules apply
// v1.1.0, 8/2/13
// * Added getSlopeRSI
// * Changed to original NB rules
// v1.1.1, 8/5/13
// * Added getGlobalMarketTrend
// * Added parameters for caching mechanism
// v1.1.2, 9/6/13
// * Added flushCache parameter

bool    libCSSsundayCandlesDetected    = false;
bool    libCSSaddSundayToMonday        = false;
bool    libCSSuseOnlySymbolOnChart     = false;
string  libCSScacheSymbol              = "EURUSD";
int     libCSScacheTimeframe           = PERIOD_M1;
string  libCSSsymbolsToWeigh           = "GBPNZD,EURNZD,GBPAUD,GBPCAD,GBPJPY,GBPCHF,CADJPY,EURCAD,EURAUD,USDCHF,GBPUSD,EURJPY,NZDJPY,AUDCHF,AUDJPY,USDJPY,EURUSD,NZDCHF,CADCHF,AUDNZD,NZDUSD,CHFJPY,AUDCAD,USDCAD,NZDCAD,AUDUSD,EURCHF,EURGBP";
int     libCSSsymbolCount;
string  libCSSsymbolNames[];
string  libCSScurrencyNames[libCSSCURRENCYCOUNT]={ "USD","EUR","GBP","CHF","JPY","AUD","CAD","NZD" };
double  libCSScurrencyValues[libCSSCURRENCYCOUNT];      // Currency slope strength
double  libCSScurrencyOccurrences[libCSSCURRENCYCOUNT]; // Holds the number of occurrences of each currency in symbols
//+------------------------------------------------------------------+
//| libCSSinit()                                                    |
//+------------------------------------------------------------------+
void libCSSinit()
  {
   libCSSinitSymbols();

   libCSSsundayCandlesDetected=false;
   for(int i=0; i<8; i++)
     {
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,i))==0)
        {
         libCSSsundayCandlesDetected=true;
         break;
        }
     }

   return;
  }
//+------------------------------------------------------------------+
//| Initialize Symbols Array                                         |
//+------------------------------------------------------------------+
int libCSSinitSymbols()
  {
   int i;

// Get extra characters on this crimmal's symbol names
   string symbolExtraChars=StringSubstrOld(Symbol(),6,4);

// Trim user input
   libCSSsymbolsToWeigh = StringTrimLeft(libCSSsymbolsToWeigh);
   libCSSsymbolsToWeigh = StringTrimRight(libCSSsymbolsToWeigh);

// Add extra comma
   if(StringSubstrOld(libCSSsymbolsToWeigh,StringLen(libCSSsymbolsToWeigh)-1)!=",")
     {
      libCSSsymbolsToWeigh=StringConcatenate(libCSSsymbolsToWeigh,",");
     }

// Split user input
   i=StringFind(libCSSsymbolsToWeigh,",");
   while(i!=-1)
     {
      int size=ArraySize(libCSSsymbolNames);
      string newSymbol=StringConcatenate(StringSubstrOld(libCSSsymbolsToWeigh,0,i),symbolExtraChars);
      if(MarketInfo(newSymbol,MODE_TRADEALLOWED)>libCSSEPSILON)
        {
         ArrayResize(libCSSsymbolNames,size+1);
         // Set array
         libCSSsymbolNames[size]=newSymbol;
        }
      // Trim symbols
      libCSSsymbolsToWeigh=StringSubstrOld(libCSSsymbolsToWeigh,i+1);
      i=StringFind(libCSSsymbolsToWeigh,",");
     }

// Kill unwanted symbols from array
   if(libCSSuseOnlySymbolOnChart)
     {
      libCSSsymbolCount=ArraySize(libCSSsymbolNames);
      string tempNames[];
      for(i=0; i<libCSSsymbolCount; i++)
        {
         for(int j=0; j<libCSSCURRENCYCOUNT; j++)
           {
            if(StringFind(Symbol(),libCSScurrencyNames[j])==-1)
              {
               continue;
              }
            if(StringFind(libCSSsymbolNames[i],libCSScurrencyNames[j])!=-1)
              {
               size=ArraySize(tempNames);
               ArrayResize(tempNames,size+1);
               tempNames[size]=libCSSsymbolNames[i];
               break;
              }
           }
        }
      for(i=0; i<ArraySize(tempNames); i++)
        {
         ArrayResize(libCSSsymbolNames,i+1);
         libCSSsymbolNames[i]=tempNames[i];
        }
     }

   libCSSsymbolCount=ArraySize(libCSSsymbolNames);
// Print("symbolCount: ", symbolCount);

   ArrayInitialize(libCSScurrencyOccurrences,0.0);
   for(i=0; i<libCSSsymbolCount; i++)
     {
      // Increase currency occurrence
      int currencyIndex=libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i],0,3));
      libCSScurrencyOccurrences[currencyIndex]++;
      currencyIndex=libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i],3,3));
      libCSScurrencyOccurrences[currencyIndex]++;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| getCurrencyIndex(string currency)                                |
//+------------------------------------------------------------------+
int libCSSgetCurrencyIndex(string currency)
  {
   for(int i=0; i<libCSSCURRENCYCOUNT; i++)
     {
      if(libCSScurrencyNames[i]==currency)
        {
         return(i);
        }
     }
   return (-1);
  }
//+------------------------------------------------------------------+
//| getSlope()                                                       |
//+------------------------------------------------------------------+
double libCSSgetSlope(string symbol,int tf,int shift)
  {
   double dblTma,dblPrev;
   int shiftWithoutSunday=shift;
   if(libCSSaddSundayToMonday && libCSSsundayCandlesDetected && tf==PERIOD_D1)
     {
      if(TimeDayOfWeek(iTime(symbol,PERIOD_D1,shift))==0) shiftWithoutSunday++;
     }
   double atr=iATR(symbol,tf,100,shiftWithoutSunday+10)/10;
   double gadblSlope=0.0;
   if(atr!=0)
     {
      dblTma=libCSScalcTmaTrue(symbol,tf,shiftWithoutSunday);
      dblPrev=libCSScalcPrevTrue(symbol,tf,shiftWithoutSunday);
      gadblSlope=(dblTma-dblPrev)/atr;
     }

   return ( gadblSlope );
  }
//+------------------------------------------------------------------+
//| calcTmaTrue()                                                    |
//+------------------------------------------------------------------+
double libCSScalcTmaTrue(string symbol,int tf,int inx)
  {
   return ( iMA( symbol, tf, 21, 0, MODE_LWMA, PRICE_CLOSE, inx ) );
  }
//+------------------------------------------------------------------+
//| calcPrevTrue()                                                   |
//+------------------------------------------------------------------+
double libCSScalcPrevTrue(string symbol,int tf,int inx)
  {
   double dblSum  = iClose( symbol, tf, inx + 1 ) * 21;
   double dblSumw = 21;
   int jnx,knx;

   dblSum  += iClose( symbol, tf, inx ) * 20;
   dblSumw += 20;

   for(jnx=1,knx=20; jnx<=20; jnx++,knx--)
     {
      dblSum  += iClose( symbol, tf, inx + 1 + jnx ) * knx;
      dblSumw += knx;
     }

   return ( dblSum / dblSumw );
  }
//+------------------------------------------------------------------+
//| getCSS( double& CSS[], int tf, int shift )                       |
//+------------------------------------------------------------------+
void libCSSgetCSS(double &css[],int tf,int shift,bool flushCache=true)
  {
   static double volume;
   if(flushCache || volume!=iVolume(libCSScacheSymbol,libCSScacheTimeframe,0) || CloseEnough(volume,0))
     {
      int i;

      ArrayInitialize(libCSScurrencyValues,0.0);

      // Get Slope for all symbols and totalize for all currencies   
      for(i=0; i<libCSSsymbolCount; i++)
        {
         double slope=libCSSgetSlope(libCSSsymbolNames[i],tf,shift);
         libCSScurrencyValues[libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 0, 3))] += slope;
         libCSScurrencyValues[libCSSgetCurrencyIndex(StringSubstrOld(libCSSsymbolNames[i], 3, 3))] -= slope;
        }
      ArrayResize(css,libCSSCURRENCYCOUNT);
      for(i=0; i<libCSSCURRENCYCOUNT; i++)
        {
         // average
         if(libCSScurrencyOccurrences[i]>0) libCSScurrencyValues[i]/=libCSScurrencyOccurrences[i]; else libCSScurrencyValues[i]=0;
        }
     }
   for(i=0; i<libCSSCURRENCYCOUNT; i++)
     {
      css[i]=libCSScurrencyValues[i];
     }
   volume=iVolume(libCSScacheSymbol,libCSScacheTimeframe,0);
  }
//+------------------------------------------------------------------+
//| getBBonStoch( string symbol, int tf, int shift )                 |
//+------------------------------------------------------------------+


bool CloseEnough(double num1,double num2)
  {
/*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */

   if(num1==0 && num2==0) return(true); //0==0
   if(MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);

//Doubles are unequal
   return(false);

  }//End bool CloseEnough(double num1, double num2)
//see also the original function by WHRoeder, http://forum.mql4.com/45425#564188, fxdaytrader
double NormalizeLots(string symbol,double lots)
  {
   if(MathAbs(lots)==0.0) return(0.0); //just in case ... otherwise it may happen that after rounding 0.0 the result is >0 and we have got a problem, fxdaytrader
   double ls=MarketInfo(symbol,MODE_LOTSTEP);
   lots=MathMin(MarketInfo(symbol,MODE_MAXLOT),MathMax(MarketInfo(symbol,MODE_MINLOT),lots)); //check if lots >= min. lots && <= max. lots, fxdaytrader
   return(MathRound(lots/ls)*ls);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetSlope(string symbol,int tf,int shift)
  {
   double atr=iATR(symbol,tf,100,shift+10)/10;
   double gadblSlope=0.0;
   if(atr!=0)
     {
      double dblTma=calcTma(symbol,tf,shift);
      double dblPrev=calcTma(symbol,tf,shift+1);
      gadblSlope=(dblTma-dblPrev)/atr;
     }

   return ( gadblSlope );

  }
//+------------------------------------------------------------------+
//| calcTma()                                                        |
//+------------------------------------------------------------------+
double calcTma(string symbol,int tf,int shift)
  {
   double dblSum  = iClose(symbol, tf, shift) * 21;
   double dblSumw = 21;
   int jnx,knx;

   for(jnx=1,knx=20; jnx<=20; jnx++,knx--)
     {
      dblSum  += ( knx * iClose(symbol, tf, shift + jnx) );
      dblSumw += knx;

      if(jnx<=shift)
        {
         dblSum  += ( knx * iClose(symbol, tf, shift - jnx) );
         dblSumw += knx;
        }
     }

   return( dblSum / dblSumw );

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*void CalculatePivots(string symbol)
{
   //Calculates the monthly and weekly pivots
   //Calculation code copied from 10.2 MonthlyMIDPivots.mq4

   //I have copied this function from BJS, and left the parameter in place in case being able to specify a different pair ever becomes useful.
   
   //Define the variables
   double last_low;//Previous candle's low
   double last_high;//Previous candle's high
   double last_close;//Previous candle's close
   double P;////Previous candle's pivot
   
   //Weekly
   last_low=iLow(symbol, PERIOD_W1, 1);
   last_high=iHigh(symbol, PERIOD_W1, 1);
   last_close=iClose(symbol, PERIOD_W1, 1);
 
   //Pivot
   P=(last_high+last_low+last_close)/3;
   WeeklyPivot = P;
  
   
   //Daily
   int shift = 1;//Need to deal with a Sunday candle
   int d = TimeDayOfWeek(TimeCurrent() );
   if (d == 1 && (BrokerHasSundayCandle )) shift = 2;
   
   last_low=iLow(symbol, PERIOD_D1, shift);
   last_high=iHigh(symbol, PERIOD_D1, shift);
   last_close=iClose(symbol, PERIOD_D1, shift);
 
   //Pivot
   P=(last_high+last_low+last_close)/3;
   DailyPivot = P;
   //Yesterday
   int yshift = 2;//Need to deal with a Sunday candle
   d = TimeDayOfWeek(TimeCurrent() );
   if (d == 2 && (BrokerHasSundayCandle )) yshift = 3;
   
   last_low=iLow(symbol, PERIOD_D1, yshift);
   last_high=iHigh(symbol, PERIOD_D1, yshift);
   last_close=iClose(symbol, PERIOD_D1, yshift);
 
   //Pivot
   P=(last_high+last_low+last_close)/3;
   YesterdayPivot = P;
   //TwoDaysBefore
   int twoshift = 3;//Need to deal with a Sunday candle
   d = TimeDayOfWeek(TimeCurrent() );
   if (d == 3 && (BrokerHasSundayCandle ))twoshift = 4;
   
   last_low=iLow(symbol, PERIOD_D1, twoshift);
   last_high=iHigh(symbol, PERIOD_D1, twoshift);
   last_close=iClose(symbol, PERIOD_D1, twoshift);
 
   //Pivot
   P=(last_high+last_low+last_close)/3;
   TwoBeforedayPivot = P;
   


}//End void CalculatePivots()*/
///////
//indi integration
//////
//
// LibSSSRv4.mqh
// Copyright © 2013, Andrew Sumner
//








int SSSR_FindZoneV2(int direction, bool useWeak, double price, double &hi, double &lo, int &strength)
{
   int zone = SSSR_FindZone(direction, useWeak, price);

   if (zone >= 0)
   {
      hi = SSSR_GetZoneHi(zone);
      lo = SSSR_GetZoneLo(zone);
      strength = SSSR_GetZoneStrength(zone);
   }

   return(zone);
}

// 
///////////////////////////////////////////////////////////////////////////////////////////////
// INTERNAL LIBRARY FUNCTIONS ONLY BELOW
///////////////////////////////////////////////////////////////////////////////////////////////

//
// SSSR_Settings
//
// Call this once when the EA inits
//

//
// SSSR_FindFractal
//
int SSSR_FindFractal(int direction, int type, int limit=1000, int shift=0, int count=0)
{
   if ((direction > SSSR_UP || direction < SSSR_DN) ||
       (type != SSSR_FAST && type != SSSR_SLOW))
      return(-1);

   if (shift < 0)
      shift = 0;

   if (count < 0)
      count = 0;

   if (limit < 100)
      limit = 100;

   int up = -1, dn = -1;
   if (type == SSSR_FAST)
   {
      if (direction >= SSSR_NONE)
         up = SSSR_FindFastUpFractal(shift, count, limit);
      if (direction <= SSSR_NONE)
         dn = SSSR_FindFastDnFractal(shift, count, limit);
   }
   else
   {
      if (direction >= SSSR_NONE)
         up = SSSR_FindSlowUpFractal(shift, count, limit);
      if (direction <= SSSR_NONE)
         dn = SSSR_FindSlowDnFractal(shift, count, limit);
   }

   if (direction == SSSR_NONE)
   {
      if (up > -1 && dn > -1)
         return(MathMin(up, dn));
      else if (up > -1)
         return(up);
      else
         return(dn);
   }
   else if (direction == SSSR_UP)
      return(up);
   else
      return(dn);
}

//
// SSSR_UpdateZones
//
// Call this to make the library recalculate the zones
//
void SSSR_UpdateZones(bool checkCandle, string symbol, int timeframe)
{
   if (SSSR_sym != symbol || SSSR_TF != timeframe)
      checkCandle = false;

   SSSR_sym = symbol;
   SSSR_TF = timeframe;

   if (checkCandle && !SSSR_NewBar())
      return;
   DeleteZones();
   SSSR_FastFractals();
   SSSR_SlowFractals();
   SSSR_FindZones();
   DrawZones();
}

//
// SSSR_FindZone
//
// Call this function to discover the closest zone to the provided price value
//
int SSSR_FindZone(int direction, bool useWeak, double price)
{
   int i, zone = -1;
   double hi = 0, lo = 99999;

   if (direction == SSSR_UP)
   {
      for (i = 0; i < SSSR_zone_count; i++)
      {
         if (SSSR_zone_hi[i] > price && (useWeak || SSSR_zone_strength[i] != SSSR_ZONE_WEAK))
         {
            if (SSSR_zone_lo[i] < lo && (SSSR_zone_type[i] == SSSR_ZONE_RESIST || SSSR_zone_lo[i] > price))
            {
               lo = SSSR_zone_lo[i];
               zone = i;
            }
         }
      }
   }
   else if (direction == SSSR_DN)
   {
      for (i = 0; i < SSSR_zone_count; i++)
      {
         if (SSSR_zone_lo[i] < price && (useWeak || SSSR_zone_strength[i] != SSSR_ZONE_WEAK))
         {
            if (SSSR_zone_hi[i] > hi && (SSSR_zone_type[i] == SSSR_ZONE_SUPPORT || SSSR_zone_hi[i] < price))
            {
               hi = SSSR_zone_hi[i];
               zone = i;
            }
         }
      }
   }
   else
      return(-1);

   return(zone);
}

int SSSR_GetZoneType(int zone)
{
   return(SSSR_zone_type[zone]);
}

double SSSR_GetZoneHi(int zone)
{
   if (zone < 0 || zone >= SSSR_zone_count)
      return(0);

   return(SSSR_zone_hi[zone]);
}

double SSSR_GetZoneLo(int zone)
{
   if (zone < 0 || zone >= SSSR_zone_count)
      return(0);

   return(SSSR_zone_lo[zone]);
}

int SSSR_GetZoneStrength(int zone)
{
   if (zone < 0 || zone >= SSSR_zone_count)
      return(0);

   return(SSSR_zone_strength[zone]);
}
int SSSR_GetZoneHits(int zone)
{
   if (zone < 0 || zone >= SSSR_zone_count)
      return(0);

   return(SSSR_zone_hits[zone]);
}

///////////////////////////////////////////////////////////////////////////////////////////////
// INTERNAL LIBRARY FUNCTIONS ONLY BELOW
///////////////////////////////////////////////////////////////////////////////////////////////

bool SSSR_NewBar()
{
   static datetime LastTime = 0;

   if (iTime(SSSR_sym, SSSR_TF, 0) > LastTime)
   {
      LastTime = iTime(SSSR_sym, SSSR_TF, 0);
      return(true);
   }

   else
      return(false);
}

bool SSSR_Fractal(int M, int P, int shift)
{
   if (SSSR_TF > P)
      P = SSSR_TF;

   if (SSSR_TF > 0)
      P = P / SSSR_TF * 2 + MathCeil(P / SSSR_TF / 2);

   if (shift < P)
      return(false);

   if (shift > iBars(SSSR_sym, SSSR_TF) - P)
      return(false);

   for (int i = 1; i <= P; i++)
   {
      if (M == SSSR_UP_POINT)
      {
         if (iHigh(SSSR_sym, SSSR_TF, shift + i) > iHigh(SSSR_sym, SSSR_TF, shift))
            return(false);

         if (iHigh(SSSR_sym, SSSR_TF, shift - i) >= iHigh(SSSR_sym, SSSR_TF, shift))
            return(false);
      }

      if (M == SSSR_DN_POINT)
      {
         if (iLow(SSSR_sym, SSSR_TF, shift + i) < iLow(SSSR_sym, SSSR_TF, shift))
            return(false);

         if (iLow(SSSR_sym, SSSR_TF, shift - i) <= iLow(SSSR_sym, SSSR_TF, shift))
            return(false);
      }
   }

   return(true);
}

int SSSR_FindFastUpFractal(int shift, int count, int limit)
{
   int found = 0;

   for (int i=shift; i<shift+limit; i++)
   {
      if (SSSR_FastUpPts[shift] > 0.00001)
      {
         found++;
         if (found > count)
            return(shift);
      }
   }

   return(-1);
}

int SSSR_FindFastDnFractal(int shift, int count, int limit)
{
   int found = 0;

   for (int i=shift; i<shift+limit; i++)
   {
      if (SSSR_FastDnPts[shift] > 0.00001)
      {
         found++;
         if (found > count)
            return(shift);
      }
   }

   return(-1);
}

int SSSR_FindSlowUpFractal(int shift, int count, int limit)
{
   int found = 0;

   for (int i=shift; i<shift+limit; i++)
   {
      if (SSSR_SlowUpPts[shift] > 0.00001)
      {
         found++;
         if (found > count)
            return(shift);
      }
   }

   return(-1);
}

int SSSR_FindSlowDnFractal(int shift, int count, int limit)
{
   int found = 0;

   for (int i=shift; i<shift+limit; i++)
   {
      if (SSSR_SlowDnPts[shift] > 0.00001)
      {
         found++;
         if (found > count)
            return(shift);
      }
   }

   return(-1);
}

void SSSR_FastFractals()
{
   int shift;
   int limit = MathMin(iBars(SSSR_sym, SSSR_TF) - 1, SSSR_BackLimit);
   int P = SSSR_TF * SSSR_zone_fastfactor;

   ArrayResize(SSSR_FastUpPts, limit);
   ArrayResize(SSSR_FastDnPts, limit);
   ArraySetAsSeries(SSSR_FastUpPts, true);
   ArraySetAsSeries(SSSR_FastDnPts, true);

   SSSR_FastUpPts[0] = 0.0;
   SSSR_FastUpPts[1] = 0.0;
   SSSR_FastDnPts[0] = 0.0;
   SSSR_FastDnPts[1] = 0.0;

   for (shift = limit; shift > 1; shift--)
   {
      SSSR_FastUpPts[shift] = 0.0;

      if (SSSR_Fractal(SSSR_UP_POINT, P, shift))
         SSSR_FastUpPts[shift] = iHigh(SSSR_sym, SSSR_TF, shift);

      SSSR_FastDnPts[shift] = 0.0;

      if (SSSR_Fractal(SSSR_DN_POINT, P, shift))
         SSSR_FastDnPts[shift] = iLow(SSSR_sym, SSSR_TF, shift);
   }
}

void SSSR_SlowFractals()
{
   int shift;
   int limit = MathMin(iBars(SSSR_sym, SSSR_TF) - 1, SSSR_BackLimit);
   int P = PERIOD_SR * SSSR_zone_slowfactor;

   ArrayResize(SSSR_SlowUpPts, limit);
   ArrayResize(SSSR_SlowDnPts, limit);
   ArraySetAsSeries(SSSR_SlowUpPts, true);
   ArraySetAsSeries(SSSR_SlowDnPts, true);

   SSSR_SlowUpPts[0] = 0.0;
   SSSR_SlowUpPts[1] = 0.0;
   SSSR_SlowDnPts[0] = 0.0;
   SSSR_SlowDnPts[1] = 0.0;

   for (shift = limit; shift > 1; shift--)
   {
      SSSR_SlowUpPts[shift] = 0.0;

      if (SSSR_Fractal(SSSR_UP_POINT, P, shift))
         SSSR_SlowUpPts[shift] = iHigh(SSSR_sym, SSSR_TF, shift);

      SSSR_SlowDnPts[shift] = 0.0;

      if (SSSR_Fractal(SSSR_DN_POINT, P, shift))
         SSSR_SlowDnPts[shift] = iLow(SSSR_sym, SSSR_TF, shift);
   }
}

void SSSR_FindZones()
{
   int i, j, shift, bustcount = 0, testcount = 0;
   double hival, loval;
   bool turned = false, hasturned = false;

   double    temp_hi[1000], temp_lo[1000];
   int       temp_start[1000], temp_hits[1000], temp_strength[1000], temp_count = 0;
   bool      temp_turn[1000], temp_merge[1000];
   int    merge1[1000], merge2[1000], merge_count = 0;

   // iterate through zones from oldest to youngest (ignore recent 5 bars),
   // finding those that have survived through to the present...
   for (shift = MathMin(iBars(SSSR_sym, SSSR_TF) - 1, SSSR_BackLimit); shift > 5; shift--)
   {
      double atr = iATR(SSSR_sym, SSSR_TF, 7, shift);
      double fu = atr / 2 * SSSR_zone_fuzzfactor;
      bool isWeak;
      bool touchOk = false;
      bool isBust = false;
      double close = iClose(SSSR_sym, SSSR_TF, shift);
      double high  = iHigh(SSSR_sym, SSSR_TF, shift);
      double low   = iLow(SSSR_sym, SSSR_TF, shift);
      double hi_i;
      double lo_i;

      if (SSSR_FastUpPts[shift] > 0.001)
      {
         // a fractal high point
         isWeak = true;

         if (SSSR_SlowUpPts[shift] > 0.001)
            isWeak = false;

         hival = high;

         if (SSSR_zone_extend == true)
            hival += fu;

         loval = MathMax(MathMin(close, high - fu), high - fu * 2);
         turned = false;
         hasturned = false;
         isBust = false;

         bustcount = 0;
         testcount = 0;

         for (i = shift - 1; i >= 0; i--)
         {
            hi_i = iHigh(SSSR_sym, SSSR_TF, i);
            lo_i = iLow(SSSR_sym, SSSR_TF, i);

            if ((!turned && SSSR_FastUpPts[i] >= loval && SSSR_FastUpPts[i] <= hival)
                  || (turned && SSSR_FastDnPts[i] <= hival && SSSR_FastDnPts[i] >= loval))
            {
               // Potential touch, just make sure its been 10+candles since the prev one
               touchOk = true;

               for (j = i + 1; j < i + 11; j++)
               {
                  if ((!turned && SSSR_FastUpPts[j] >= loval && SSSR_FastUpPts[j] <= hival)
                        || (turned && SSSR_FastDnPts[j] <= hival && SSSR_FastDnPts[j] >= loval))
                  {
                     touchOk = false;
                     break;
                  }
               }

               if (touchOk)
               {
                  // we have a touch.  If its been busted once, remove bustcount
                  // as we know this level is still valid & has just switched sides
                  bustcount = 0;
                  testcount++;
               }
            }

            if ((turned == false && hi_i > hival)
                  || (turned == true && lo_i < loval))
            {
               // this level has been busted at least once
               bustcount++;

               if (bustcount > 1 || isWeak == true)
               {
                  // busted twice or more
                  isBust = true;
                  break;
               }

               turned = !turned;

               hasturned = true;

               // forget previous hits
               testcount = 0;
            }
         }

         if (!isBust)
         {
            // level is still valid, add to our list
            temp_hi[temp_count] = hival;
            temp_lo[temp_count] = loval;
            temp_turn[temp_count] = hasturned;
            temp_hits[temp_count] = testcount;
            temp_start[temp_count] = shift;
            temp_merge[temp_count] = false;

            if (testcount > 3)
               temp_strength[temp_count] = SSSR_ZONE_PROVEN;

            else
               if (testcount > 0)
                  temp_strength[temp_count] = SSSR_ZONE_VERIFIED;

               else
                  if (hasturned)
                     temp_strength[temp_count] = SSSR_ZONE_TURNCOAT;

                  else
                     if (!isWeak)
                        temp_strength[temp_count] = SSSR_ZONE_UNTESTED;

                     else
                        temp_strength[temp_count] = SSSR_ZONE_WEAK;

            temp_count++;
         }
      }

      else
         if (SSSR_FastDnPts[shift] > 0.001)
         {
            // a zigzag low point
            isWeak = true;

            if (SSSR_SlowDnPts[shift] > 0.001)
               isWeak = false;

            loval = low;

            if (SSSR_zone_extend == true)
               loval -= fu;

            hival = MathMin(MathMax(close, low + fu), low + fu * 2);
            turned = false;
            hasturned = false;

            bustcount = 0;
            testcount = 0;
            isBust = false;

            for (i = shift - 1; i >= 0; i--)
            {
               hi_i = iHigh(SSSR_sym, SSSR_TF, i);
               lo_i = iLow(SSSR_sym, SSSR_TF, i);

               if ((turned && SSSR_FastUpPts[i] >= loval && SSSR_FastUpPts[i] <= hival)
                     || (!turned && SSSR_FastDnPts[i] <= hival && SSSR_FastDnPts[i] >= loval))
               {
                  // Potential touch, just make sure its been 10+candles since the prev one
                  touchOk = true;

                  for (j = i + 1; j < i + 11; j++)
                  {
                     if ((turned && SSSR_FastUpPts[j] >= loval && SSSR_FastUpPts[j] <= hival)
                           || (!turned && SSSR_FastDnPts[j] <= hival && SSSR_FastDnPts[j] >= loval))
                     {
                        touchOk = false;
                        break;
                     }
                  }

                  if (touchOk)
                  {
                     // we have a touch.  If its been busted once, remove bustcount
                     // as we know this level is still valid & has just switched sides
                     bustcount = 0;
                     testcount++;
                  }
               }

               if ((turned && hi_i > hival)
                     || (!turned && lo_i < loval))
               {
                  // this level has been busted at least once
                  bustcount++;

                  if (bustcount > 1 || isWeak)
                  {
                     // busted twice or more
                     isBust = true;
                     break;
                  }

                  turned = !turned;

                  hasturned = true;

                  // forget previous hits
                  testcount = 0;
               }
            }

            if (!isBust)
            {
               // level is still valid, add to our list
               temp_hi[temp_count] = hival;
               temp_lo[temp_count] = loval;
               temp_turn[temp_count] = hasturned;
               temp_hits[temp_count] = testcount;
               temp_start[temp_count] = shift;
               temp_merge[temp_count] = false;

               if (testcount > 3)
                  temp_strength[temp_count] = SSSR_ZONE_PROVEN;

               else
                  if (testcount > 0)
                     temp_strength[temp_count] = SSSR_ZONE_VERIFIED;

                  else
                     if (hasturned)
                        temp_strength[temp_count] = SSSR_ZONE_TURNCOAT;

                     else
                        if (!isWeak)
                           temp_strength[temp_count] = SSSR_ZONE_UNTESTED;

                        else
                           temp_strength[temp_count] = SSSR_ZONE_WEAK;

               temp_count++;
            }
         }
   }

   // look for overlapping zones...
   if (SSSR_zone_merge)
   {
      merge_count = 1;
      int iterations = 0;

      while (merge_count > 0 && iterations < 3)
      {
         merge_count = 0;
         iterations++;

         for (i = 0; i < temp_count; i++)
            temp_merge[i] = false;

         for (i = 0; i < temp_count - 1; i++)
         {
            if (temp_hits[i] == -1 || temp_merge[j])
               continue;

            for (j = i + 1; j < temp_count; j++)
            {
               if (temp_hits[j] == -1 || temp_merge[j])
                  continue;

               if ((temp_hi[i] >= temp_lo[j] && temp_hi[i] <= temp_hi[j])
                     || (temp_lo[i] <= temp_hi[j] && temp_lo[i] >= temp_lo[j])
                     || (temp_hi[j] >= temp_lo[i] && temp_hi[j] <= temp_hi[i])
                     || (temp_lo[j] <= temp_hi[i] && temp_lo[j] >= temp_lo[i]))
               {
                  merge1[merge_count] = i;
                  merge2[merge_count] = j;
                  temp_merge[i] = true;
                  temp_merge[j] = true;
                  merge_count++;
               }
            }
         }

         // ... and merge them ...
         for (i = 0; i < merge_count; i++)
         {
            int target = merge1[i];
            int source = merge2[i];

            temp_hi[target] = MathMax(temp_hi[target], temp_hi[source]);
            temp_lo[target] = MathMin(temp_lo[target], temp_lo[source]);
            temp_hits[target] += temp_hits[source];
            temp_start[target] = MathMax(temp_start[target], temp_start[source]);
            temp_strength[target] = MathMax(temp_strength[target], temp_strength[source]);

            if (temp_hits[target] > 3)
               temp_strength[target] = SSSR_ZONE_PROVEN;

            if (temp_hits[target] == 0 && !temp_turn[target])
            {
               temp_hits[target] = 1;

               if (temp_strength[target] < SSSR_ZONE_VERIFIED)
                  temp_strength[target] = SSSR_ZONE_VERIFIED;
            }

            if (!temp_turn[target] || !temp_turn[source])
               temp_turn[target] = false;

            if (temp_turn[target])
               temp_hits[target] = 0;

            temp_hits[source] = -1;
         }
      }
   }

   // copy the remaining list into our official zones arrays
   SSSR_zone_count = 0;

   for (i = 0; i < temp_count; i++)
   {
      if (temp_hits[i] >= 0 && SSSR_zone_count < 1000)
      {
         SSSR_zone_hi[SSSR_zone_count]       = temp_hi[i];
         SSSR_zone_lo[SSSR_zone_count]       = temp_lo[i];
         SSSR_zone_hits[SSSR_zone_count]     = temp_hits[i];
         SSSR_zone_turn[SSSR_zone_count]     = temp_turn[i];
         SSSR_zone_start[SSSR_zone_count]    = temp_start[i];
         SSSR_zone_strength[SSSR_zone_count] = temp_strength[i];

         if (SSSR_zone_hi[SSSR_zone_count] < Close[4])
            SSSR_zone_type[SSSR_zone_count] = SSSR_ZONE_SUPPORT;

         else
            if (SSSR_zone_lo[SSSR_zone_count] > Close[4])
               SSSR_zone_type[SSSR_zone_count] = SSSR_ZONE_RESIST;

            else
            {
               for (j = 5; j < 1000; j++)
               {
                  if (iClose(SSSR_sym, SSSR_TF, j) < SSSR_zone_lo[SSSR_zone_count])
                  {
                     SSSR_zone_type[SSSR_zone_count] = SSSR_ZONE_RESIST;
                     break;
                  }

                  else
                     if (iClose(SSSR_sym, SSSR_TF, j) > SSSR_zone_hi[SSSR_zone_count])
                     {
                        SSSR_zone_type[SSSR_zone_count] = SSSR_ZONE_SUPPORT;
                        break;
                     }
               }

               if (j == 1000)
                  SSSR_zone_type[SSSR_zone_count] = SSSR_ZONE_SUPPORT;
            }

         SSSR_zone_count++;
      }
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar(int TimeFrame)
  {
   static datetime LastTime=0;
   if(iTime(NULL,TimeFrame,0)!=LastTime)
     {
      LastTime=iTime(NULL,TimeFrame,0);
      return (true);
     }
   else
      return (false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PartCloseTrade(int ticket)
  {
//Close MoveOnSLPartClosePercent of the initial trade.
//Return true if close succeeds, else false
   if(!OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) return(true);//in case the trade closed
   double CloseLots=NormalizeLots(OrderSymbol(),OrderLots() *(PartClosePercent/100));
   bool Success=OrderClose(ticket,CloseLots,OrderClosePrice(),1000,Blue); //fxdaytrader, NormalizeLots(...

   if(!Success)
     {
      //mod. fxdaytrader, orderclose-retry if failed with ordercloseprice(). Maybe very seldom, but it can happen, so it does not hurt to implement this:
      while(IsTradeContextBusy()) Sleep(100);
      RefreshRates();
      if(OrderType()==OP_BUY) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_BID), 5000, Blue);
      if(OrderType()==OP_SELL) Success = OrderClose(ticket, CloseLots, MarketInfo(OrderSymbol(),MODE_ASK), 5000, Blue);
      //end mod.  
      //original:
      if(!Success)
        {
         Alert(" PartCloseTrade() failed!!");
         return (false);
        }
     }//if (!Success) 

//Got this far, so closure succeeded
   return (true);

  }//bool PartCloseTrade(int ticket)
// for 6xx build compatibilità added by milanese

string StringSubstrOld(string x,int a,int b=-1)
  {
   if(a<0) a=0; // Stop odd behaviour
   if(b<=0) b=-1; // new MQL4 EOL flag
   return StringSubstr(x,a,b);
  }
//+------------------------------------------------------------------+
void DrawZones()
  {
   

   for(int i=0; i<SSSR_zone_count; i++)
     {
     

      string s="SSSR#"+i+" Strength=";
      if(SSSR_zone_strength[i]==SSSR_ZONE_PROVEN)
         s=s+"Proven, Test Count="+SSSR_zone_hits[i];
      else if(SSSR_zone_strength[i]==SSSR_ZONE_VERIFIED)
         s=s+"Verified, Test Count="+SSSR_zone_hits[i];
      else if(SSSR_zone_strength[i]==SSSR_ZONE_UNTESTED)
         s=s+"Untested";
      else if(SSSR_zone_strength[i]==SSSR_ZONE_TURNCOAT)
         s=s+"Turncoat";
      else
         s=s+"Weak";

      ObjectCreate(s,OBJ_RECTANGLE,0,0,0,0,0);
      ObjectSet(s,OBJPROP_TIME1,iTime(NULL,PERIOD_SR,SSSR_zone_start[i]));
      ObjectSet(s,OBJPROP_TIME2,TimeCurrent());
      ObjectSet(s,OBJPROP_PRICE1,SSSR_zone_hi[i]);
      ObjectSet(s,OBJPROP_PRICE2,SSSR_zone_lo[i]);
      ObjectSet(s,OBJPROP_BACK,zone_solid);
      ObjectSet(s,OBJPROP_WIDTH,zone_linewidth);
      ObjectSet(s,OBJPROP_STYLE, zone_style);

      if(SSSR_zone_type[i]==SSSR_ZONE_SUPPORT)
        {
         // support zone
         if(SSSR_zone_strength[i]==SSSR_ZONE_TURNCOAT)
            ObjectSet(s,OBJPROP_COLOR,color_support_turncoat);
         else if(SSSR_zone_strength[i]==SSSR_ZONE_PROVEN)
            ObjectSet(s,OBJPROP_COLOR,color_support_proven);
         else if(SSSR_zone_strength[i]==SSSR_ZONE_VERIFIED)
            ObjectSet(s,OBJPROP_COLOR,color_support_verified);
         else if(SSSR_zone_strength[i]==SSSR_ZONE_UNTESTED)
            ObjectSet(s,OBJPROP_COLOR,color_support_untested);
         else
            ObjectSet(s,OBJPROP_COLOR,color_support_weak);
        }
      else
        {
         // resistance zone
         if(SSSR_zone_strength[i]==SSSR_ZONE_TURNCOAT)
            ObjectSet(s,OBJPROP_COLOR,color_resist_turncoat);
         else if(SSSR_zone_strength[i]==SSSR_ZONE_PROVEN)
            ObjectSet(s,OBJPROP_COLOR,color_resist_proven);
         else if(SSSR_zone_strength[i]==SSSR_ZONE_VERIFIED)
            ObjectSet(s,OBJPROP_COLOR,color_resist_verified);
         else if(SSSR_zone_strength[i]==SSSR_ZONE_UNTESTED)
            ObjectSet(s,OBJPROP_COLOR,color_resist_untested);
         else
            ObjectSet(s,OBJPROP_COLOR,color_resist_weak);
        }

      
     }
  }
  void DeleteZones()
  {
   int len=5;
   int i;

   while(i<ObjectsTotal())
     {
      string objName=ObjectName(i);
      if(StringSubstrOld(objName,0,len)!="SSSR#")
        {
         i++;
         continue;
        }
      ObjectDelete(objName);
     }
  }
  string StringRightPad(string str,int n=1,string str2=" ")
  {
   return(str + StringRepeat(str2,n-StringLen(str)));
  }
  string StringRepeat(string str,int n=1)
  {
   string outstr="";
   for(int i=0; i<n; i++) outstr=outstr+str;
   return(outstr);
  }